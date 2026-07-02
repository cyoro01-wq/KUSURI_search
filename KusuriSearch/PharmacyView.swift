import SwiftUI
import MapKit
import CoreLocation
import WebKit

// MARK: - LocationManager
@MainActor
final class LocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var status: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        status = manager.authorizationStatus
    }

    func requestCurrentLocation() async -> CLLocation? {
        if let location, isUsableLocation(location) {
            return location
        }

        guard CLLocationManager.locationServicesEnabled() else {
            return nil
        }

        let authorization = manager.authorizationStatus
        if authorization == .denied || authorization == .restricted {
            return nil
        }

        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            startSingleLocationRequest()
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                if locationContinuation != nil {
                    finishLocationRequest(with: location)
                }
            }
        }
    }

    private func startSingleLocationRequest() {
        manager.requestLocation()
        manager.startUpdatingLocation()
    }

    private func finishLocationRequest(with location: CLLocation?) {
        manager.stopUpdatingLocation()
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    private func isUsableLocation(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 150 else { return false }
        return abs(location.timestamp.timeIntervalSinceNow) <= 30
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        let bestLocation = locs
            .filter { $0.horizontalAccuracy >= 0 }
            .sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }
            .first ?? locs.last

        if let bestLocation {
            location = bestLocation
            if isUsableLocation(bestLocation) || locationContinuation != nil {
                finishLocationRequest(with: bestLocation)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location: \(error)")
        finishLocationRequest(with: location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if locationContinuation != nil {
                startSingleLocationRequest()
            }
        case .denied, .restricted:
            finishLocationRequest(with: nil)
        default:
            break
        }
    }
}

// MARK: - PharmacyView
struct PharmacyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var locationManager = LocationManager()
    @State private var query = ""
    @State private var pharmacies: [Pharmacy] = []
    @State private var loading = false
    @State private var searched = false
    @State private var locationErrorMessage: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @FocusState private var queryFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("エリア名・駅名を入力", text: $query)
                            .focused($queryFieldFocused)
                            .onSubmit { Task { await searchByQuery(query) } }
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        queryFieldFocused = false
                    }
                    .padding(10).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 8) {
                        Button {
                            queryFieldFocused = false
                            Task { await searchWithLocation() }
                        } label: {
                            Label("現在地で検索", systemImage: "location.fill")
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(maxWidth: .infinity).padding(10)
                                .background(Color.appPurple).foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Button {
                            queryFieldFocused = false
                            Task { await searchByQuery(query.isEmpty ? "新宿" : query) }
                        } label: {
                            Text("検索")
                                .fontWeight(.semibold).padding(10).padding(.horizontal, 4)
                                .background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .foregroundColor(.primary)
                    }

                    if let locationErrorMessage {
                        Text(locationErrorMessage)
                            .font(.caption)
                            .foregroundColor(.appRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal).padding(.vertical, 10)

                Divider()

                if loading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.3)
                        Text("薬局を検索中...").foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searched && !pharmacies.isEmpty {
                    // Map
                    Map(position: .constant(.region(region))) {
                        ForEach(pharmacies) { ph in
                            Annotation(ph.name, coordinate: ph.coordinate) {
                                PharmacyPin(status: ph.currentStatus, isFav: appState.favPharmacies.contains(ph.id))
                            }
                        }
                    }
                    .frame(height: 180)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            queryFieldFocused = false
                        }
                    )

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(pharmacies) { ph in
                                PharmacyRow(pharmacy: ph)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            queryFieldFocused = false
                        }
                    )
                } else if !searched {
                    Spacer()
                    ContentUnavailableView(
                        "薬局を検索しましょう",
                        systemImage: "cross.vial",
                        description: Text("現在地または地名・駅名で\n近くの調剤薬局・ドラッグストアを探せます")
                    )
                    .onTapGesture {
                        queryFieldFocused = false
                    }
                    Spacer()
                } else {
                    ContentUnavailableView("薬局が見つかりませんでした", systemImage: "mappin.slash")
                        .onTapGesture {
                            queryFieldFocused = false
                        }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("📍 薬局を探す")
            .contentShape(Rectangle())
            .onTapGesture {
                queryFieldFocused = false
            }
        }
    }

    func searchWithLocation() async {
        loading = true
        locationErrorMessage = nil

        if let loc = await locationManager.requestCurrentLocation() {
            region.center = loc.coordinate
            await searchMKLocal(near: loc.coordinate, label: "現在地付近")
        } else {
            loading = false
            searched = !pharmacies.isEmpty
            locationErrorMessage = "現在地を取得できませんでした。iPhone の位置情報設定を確認して、再度お試しください。"
        }
    }

    func searchByQuery(_ q: String) async {
        guard !q.isEmpty else { return }
        loading = true
        locationErrorMessage = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        request.resultTypes = [.pointOfInterest, .address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let firstItem = response.mapItems.first else {
                pharmacies = []
                loading = false
                searched = true
                locationErrorMessage = "「\(q)」の場所を特定できませんでした。駅名・地名をもう少し詳しく入力してください。"
                return
            }

            let coord = firstItem.location.coordinate
            region.center = coord
            await searchMKLocal(near: coord, label: q)
        } catch {
            pharmacies = []
            loading = false
            searched = true
            locationErrorMessage = "「\(q)」の検索に失敗しました。通信状況を確認して再度お試しください。"
        }
    }

    func searchMKLocal(near coord: CLLocationCoordinate2D, label: String) async {
        let userLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let searchRegion = MKCoordinateRegion(center: coord,
            latitudinalMeters: 2000, longitudinalMeters: 2000)

        // 単独の調剤薬局だけでなく、ドラッグストア併設の調剤薬局も拾えるように
        // 複数キーワードで並列検索して結果を統合する
        // MKMapItem は Sendable でないためタスク内で Pharmacy に変換して返す
        let keywords = ["調剤薬局", "薬局", "ドラッグストア"]
        let candidates = await withTaskGroup(of: [Pharmacy].self) { group in
            for keyword in keywords {
                group.addTask {
                    let request = MKLocalSearch.Request()
                    request.naturalLanguageQuery = keyword
                    request.region = searchRegion
                    request.resultTypes = .pointOfInterest
                    guard let items = (try? await MKLocalSearch(request: request).start())?.mapItems else {
                        return []
                    }
                    return items.map { Pharmacy.from(mapItem: $0, userLocation: userLoc) }
                }
            }
            var all: [Pharmacy] = []
            for await items in group {
                all += items
            }
            return all
        }

        // 同じ店舗が複数キーワードでヒットするため、名前 + 位置（約10m単位）で重複排除
        var seen: Set<String> = []
        var results: [Pharmacy] = []
        for pharmacy in candidates {
            let key = [
                pharmacy.name,
                String(format: "%.4f", pharmacy.coordinate.latitude),
                String(format: "%.4f", pharmacy.coordinate.longitude)
            ].joined(separator: "|")
            guard seen.insert(key).inserted else { continue }
            results.append(pharmacy)
        }
        results.sort { ($0.distance ?? 999) < ($1.distance ?? 999) }

        pharmacies = results
        if results.isEmpty {
            locationErrorMessage = "「\(label)」周辺で薬局が見つかりませんでした。"
        }
        region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        loading = false; searched = true
    }
}

// MARK: - PharmacyPin
private struct PharmacyPin: View {
    let status: Pharmacy.OpenStatus
    let isFav: Bool
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "mappin.circle.fill")
                .font(.title).foregroundColor(pinColor)
                .shadow(radius: 2)
            if isFav {
                Circle().fill(Color.appPink).frame(width: 10, height: 10)
                    .offset(x: 2, y: -2)
            }
        }
    }

    private var pinColor: Color {
        switch status {
        case .open:
            return .appGreen
        case .closed:
            return .appRed
        case .unknown:
            return .secondary
        }
    }
}

// MARK: - PharmacyRow
struct PharmacyRow: View {
    @EnvironmentObject var appState: AppState
    let pharmacy: Pharmacy
    @State private var showHours = false
    @State private var showMap = false

    private var currentStatus: Pharmacy.OpenStatus {
        pharmacy.currentStatus
    }

    private var statusLabel: String {
        switch currentStatus {
        case .open:
            return "営業中"
        case .closed:
            return "営業時間外"
        case .unknown:
            return "営業時間情報なし"
        }
    }

    private var statusColor: Color {
        switch currentStatus {
        case .open:
            return .appGreen
        case .closed:
            return .appRed
        case .unknown:
            return .secondary
        }
    }

    private var phoneURL: URL? {
        guard let phone = pharmacy.phone?.replacingOccurrences(of: "-", with: "") else { return nil }
        return URL(string: "tel:\(phone)")
    }

    private var routeURL: URL? {
        var components = URLComponents(string: "https://www.google.com/maps/dir/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: "\(pharmacy.coordinate.latitude),\(pharmacy.coordinate.longitude)"),
            URLQueryItem(name: "travelmode", value: "walking")
        ]
        return components?.url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pharmacy.name).font(.headline)
                        Text(statusLabel)
                            .font(.caption2).fontWeight(.bold)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(statusColor.opacity(0.15))
                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                    }
                    Text(pharmacy.address).font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        if let dist = pharmacy.distance {
                            Label(String(format: "%.1fkm", dist), systemImage: "location")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        if pharmacy.rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill").foregroundColor(.appYellow)
                                Text(String(format: "%.1f", pharmacy.rating))
                                Text("(\(pharmacy.totalRatings)件)").foregroundColor(.secondary)
                            }.font(.caption)
                        }
                    }
                }
                Spacer()
                Button { appState.togglePharmacy(pharmacy) } label: {
                    Image(systemName: appState.favPharmacies.contains(pharmacy.id) ? "heart.fill" : "heart")
                        .foregroundColor(appState.favPharmacies.contains(pharmacy.id) ? .appPink : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                if let phone = pharmacy.phone, let phoneURL {
                    Link(destination: phoneURL) {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption).fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding(8)
                            .background(Color.appGreen.opacity(0.12)).foregroundColor(.appGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                Button {
                    showMap = true
                } label: {
                        Label("地図", systemImage: "map.fill")
                            .font(.caption).fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding(8)
                            .background(Color.appBlue.opacity(0.12)).foregroundColor(.appBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                if let routeURL {
                    Link(destination: routeURL) {
                        Label("ルート", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.caption).fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding(8)
                            .background(Color.appPurple.opacity(0.12)).foregroundColor(.appPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if !pharmacy.hours.isEmpty {
                Button { withAnimation { showHours.toggle() } } label: {
                    HStack {
                        Label("営業時間", systemImage: "clock").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: showHours ? "chevron.up" : "chevron.down")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                if showHours {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(pharmacy.hours.sorted(by: { $0.key < $1.key }), id: \.key) { day, time in
                            HStack {
                                Text(day).font(.caption).foregroundColor(.secondary).frame(width: 40, alignment: .leading)
                                Text(time).font(.caption)
                            }
                        }
                    }
                    .padding(10).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(14)
        .background(appState.favPharmacies.contains(pharmacy.id)
            ? Color.appPink.opacity(0.05)
            : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(appState.favPharmacies.contains(pharmacy.id) ? Color.appPink : Color.clear, lineWidth: 1.5))
        .fullScreenCover(isPresented: $showMap) {
            PharmacyMapDetailView(pharmacy: pharmacy)
        }
    }
}

private struct PharmacyMapDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let pharmacy: Pharmacy

    private var googleMapURL: URL {
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: "\(pharmacy.coordinate.latitude),\(pharmacy.coordinate.longitude)")
        ]
        return components?.url ?? URL(string: "https://www.google.com/maps")!
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GoogleMapWebView(url: googleMapURL)
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Label("戻る", systemImage: "chevron.left")
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                        .shadow(radius: 8, y: 3)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pharmacy.name)
                        .font(.headline)
                    Text(pharmacy.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 8, y: 3)
            }
            .padding(.leading, 18)
            .padding(.bottom, 24)
        }
    }
}

private struct GoogleMapWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}
