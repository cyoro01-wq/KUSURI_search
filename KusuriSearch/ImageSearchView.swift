import SwiftUI
import PhotosUI
import Vision

// MARK: - Analysis Models

struct MedicineMatch: Identifiable {
    let id = UUID()
    let medicine: Medicine
    let score: Double
    let matchedKeywords: [String]

    var confidence: String {
        if score >= 2.0 { return "high" }
        if score >= 0.8 { return "medium" }
        return "low"
    }
    var confidenceLabel: String {
        switch confidence {
        case "high":   return "高精度"
        case "medium": return "中精度"
        default:       return "低精度"
        }
    }
    var confidenceColor: Color {
        switch confidence {
        case "high":   return .appGreen
        case "medium": return .appOrange
        default:       return .appRed
        }
    }
}

struct AnalysisResult {
    let detectedTexts: [String]
    let barcodes: [String]
    let searchQueries: [String]
    let matches: [MedicineMatch]
}

// MARK: - On-Device Analyzer (Vision Framework)

enum MedicineAnalyzer {
    static func analyze(image: UIImage) async -> AnalysisResult {
        guard let prepared = preparedImage(from: image) else {
            return AnalysisResult(detectedTexts: [], barcodes: [], searchQueries: [], matches: [])
        }
        async let texts    = extractText(prepared.cgImage, orientation: prepared.orientation)
        async let barcodes = detectBarcodes(prepared.cgImage, orientation: prepared.orientation)
        let (t, b) = await (texts, barcodes)
        let medicines = await MainActor.run { MedicineRepository.shared.allMedicines }
        let queries = prioritizedQueries(texts: t, barcodes: b)
        let preferredQueries = queries.filter(isMedicineSearchQuery(_:))

        // まず端末内DBを照合し、確度の高い一致（名称・識別コードの完全一致）が
        // あれば通信せずに即時返す
        let directMatches = searchMedicines(using: queries, medicines: medicines)
        if let best = directMatches.first, best.score >= 8.0 {
            return AnalysisResult(
                detectedTexts: t,
                barcodes: b,
                searchQueries: queries,
                matches: mergeMatches(primary: directMatches, secondary: [])
            )
        }

        let fuzzyMatches = matchMedicines(texts: t, barcodes: b, medicines: medicines)
        let localMatches = mergeMatches(primary: directMatches, secondary: fuzzyMatches)

        let remoteMatches = await searchRemoteMedicines(using: preferredQueries.isEmpty ? queries : preferredQueries)
        let mergedMatches = remoteMatches.isEmpty
            ? localMatches
            : mergeMatches(primary: remoteMatches, secondary: localMatches)
        return AnalysisResult(detectedTexts: t, barcodes: b, searchQueries: queries, matches: mergedMatches)
    }

    static func searchDetectedText(_ text: String, preserving result: AnalysisResult) async -> AnalysisResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return result }

        let medicines = await MainActor.run { MedicineRepository.shared.allMedicines }
        let queries = prioritizedQueries(texts: [trimmed], barcodes: [])
        let searchQueries = queries.isEmpty ? [trimmed] : queries
        let preferredQueries = searchQueries.filter(isMedicineSearchQuery(_:))
        let remoteQueries = preferredQueries.isEmpty ? searchQueries : preferredQueries
        let remoteMatches = await searchRemoteMedicines(using: remoteQueries)
        let localMatches = searchMedicines(using: searchQueries, medicines: medicines)
        let fuzzyMatches = matchMedicines(texts: [trimmed], barcodes: [], medicines: medicines)
        let mergedMatches = mergeMatches(
            primary: mergeMatches(primary: remoteMatches, secondary: localMatches),
            secondary: fuzzyMatches
        )

        let mergedQueries = ([trimmed] + searchQueries + result.searchQueries).deduplicatedByNormalizedToken()
        return AnalysisResult(
            detectedTexts: result.detectedTexts,
            barcodes: result.barcodes,
            searchQueries: mergedQueries,
            matches: mergedMatches
        )
    }

    /// Vision へ渡す画像を用意する。巨大画像は解析が極端に遅くなるため縮小し、
    /// 撮影向き（EXIF orientation）も引き継いで認識精度を保つ。
    private static func preparedImage(from image: UIImage) -> (cgImage: CGImage, orientation: CGImagePropertyOrientation)? {
        guard let cgImage = image.cgImage else { return nil }

        let maxDimension: CGFloat = 2000
        let pixelSize = CGSize(width: image.size.width * image.scale,
                               height: image.size.height * image.scale)
        let largest = max(pixelSize.width, pixelSize.height)
        guard largest > maxDimension else {
            return (cgImage, CGImagePropertyOrientation(image.imageOrientation))
        }

        let ratio = maxDimension / largest
        let newSize = CGSize(width: pixelSize.width * ratio, height: pixelSize.height * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let resizedCG = resized.cgImage else {
            return (cgImage, CGImagePropertyOrientation(image.imageOrientation))
        }
        // draw(in:) は向きを正規化して描画するため orientation は .up になる
        return (resizedCG, .up)
    }

    // OCR（日本語 + 英語）
    private static func extractText(_ cg: CGImage, orientation: CGImagePropertyOrientation) async -> [String] {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let req = VNRecognizeTextRequest()
                req.recognitionLevel       = .accurate
                req.recognitionLanguages   = ["ja-JP", "en-US"]
                req.usesLanguageCorrection = true
                try? VNImageRequestHandler(cgImage: cg, orientation: orientation).perform([req])

                // 信頼度の低い読み取り結果はノイズになるため除外する
                let texts = (req.results ?? []).compactMap { observation -> String? in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence >= 0.3 else { return nil }
                    return candidate.string
                }
                cont.resume(returning: texts)
            }
        }
    }

    // バーコード検出
    private static func detectBarcodes(_ cg: CGImage, orientation: CGImagePropertyOrientation) async -> [String] {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let req = VNDetectBarcodesRequest()
                try? VNImageRequestHandler(cgImage: cg, orientation: orientation).perform([req])
                let codes = (req.results ?? []).compactMap { $0.payloadStringValue }
                cont.resume(returning: codes)
            }
        }
    }

    // テキスト → 薬品マッチング
    private static func matchMedicines(texts: [String], barcodes: [String], medicines: [Medicine]) -> [MedicineMatch] {
        let combined = (texts + barcodes).joined(separator: " ").lowercased()
        let normalizedLines = texts.map(normalizeToken).filter { !$0.isEmpty }
        let normalizedTokens = Set(
            texts
                .flatMap(searchTokens(from:))
                .map(normalizeToken)
                .filter { !$0.isEmpty }
        )
        let normalizedCombined = normalizeToken(combined)
        var results: [MedicineMatch] = []

        for med in medicines {
            var score = 0.0
            var matched: Set<String> = []
            let normalizedBrand = normalizeToken(med.brandName)
            let normalizedGeneric = normalizeToken(med.genericName)
            let normalizedName = normalizeToken(med.name)
            let normalizedKana = normalizeToken(med.kana)
            let normalizedImprints = med.imprintCodes
                .map(normalizeToken)
                .filter { !$0.isEmpty }

            func check(_ keyword: String, pts: Double) {
                if combined.contains(keyword.lowercased()) {
                    score += pts; matched.insert(keyword)
                }
            }

            if normalizedTokens.contains(normalizedBrand) || normalizedLines.contains(normalizedBrand) {
                score += 7.0
                matched.insert(med.brandName)
            }
            if normalizedTokens.contains(normalizedGeneric) || normalizedLines.contains(normalizedGeneric) {
                score += 6.0
                matched.insert(med.genericName)
            }
            if normalizedTokens.contains(normalizedName) || normalizedLines.contains(normalizedName) {
                score += 5.0
                matched.insert(med.name)
            }
            if normalizedTokens.contains(normalizedKana) || normalizedLines.contains(normalizedKana) {
                score += 4.0
                matched.insert(med.kana)
            }
            if normalizedTokens.contains(where: { normalizedImprints.contains($0) }) {
                score += 7.2
                matched.formUnion(med.imprintCodes)
            }

            if normalizedCombined.contains(normalizedBrand) {
                score += 4.2
                matched.insert(med.brandName)
            }
            if normalizedCombined.contains(normalizedGeneric) {
                score += 3.8
                matched.insert(med.genericName)
            }
            if normalizedCombined.contains(normalizedName) {
                score += 3.0
                matched.insert(med.name)
            }
            if normalizedCombined.contains(normalizedKana) {
                score += 2.4
                matched.insert(med.kana)
            }
            if normalizedImprints.contains(where: { normalizedCombined.contains($0) || $0.contains(normalizedCombined) }) {
                score += 4.8
                matched.formUnion(med.imprintCodes)
            }

            check(med.maker, pts: 0.2)
            for tag in med.tags { check(tag, pts: 0.15) }
            for kw in categoryKeywords(med.category) { check(kw, pts: 0.1) }

            for token in normalizedTokens where token.count >= 3 {
                if normalizedBrand.contains(token) || token.contains(normalizedBrand) {
                    score += token.count >= 5 ? 2.0 : 1.2
                    matched.insert(med.brandName)
                }
                if normalizedGeneric.contains(token) || token.contains(normalizedGeneric) {
                    score += token.count >= 5 ? 1.6 : 1.0
                    matched.insert(med.genericName)
                }
                if normalizedName.contains(token) || token.contains(normalizedName) {
                    score += token.count >= 5 ? 1.4 : 0.9
                    matched.insert(med.name)
                }
                if normalizedKana.contains(token) || token.contains(normalizedKana) {
                    score += 0.8
                    matched.insert(med.kana)
                }
                if normalizedImprints.contains(where: { $0.contains(token) || token.contains($0) }) {
                    score += token.count >= 4 ? 2.2 : 1.4
                    matched.formUnion(med.imprintCodes)
                }
            }

            let strongMatch = matched.contains(med.brandName) || matched.contains(med.genericName) || matched.contains(med.name) || matched.contains(med.kana)
            let partialHitCount = normalizedTokens.filter {
                normalizedBrand.contains($0) || normalizedGeneric.contains($0) || normalizedName.contains($0) || normalizedKana.contains($0)
            }.count

            if score >= 1.4 && (strongMatch || partialHitCount >= 2) {
                results.append(MedicineMatch(medicine: med, score: score,
                                             matchedKeywords: Array(matched).sorted()))
            }
        }
        return results.sorted { $0.score > $1.score }
    }

    private static func searchMedicines(using queries: [String], medicines: [Medicine]) -> [MedicineMatch] {
        var scored: [Int: (medicine: Medicine, score: Double, matched: Set<String>)] = [:]

        for query in queries {
            let normalizedQuery = normalizeToken(query)
            guard !normalizedQuery.isEmpty else { continue }

            for med in medicines {
                let normalizedBrand = normalizeToken(med.brandName)
                let normalizedGeneric = normalizeToken(med.genericName)
                let normalizedName = normalizeToken(med.name)
                let normalizedKana = normalizeToken(med.kana)
                let normalizedImprints = med.imprintCodes
                    .map(normalizeToken)
                    .filter { !$0.isEmpty }

                var delta = 0.0
                if normalizedBrand == normalizedQuery { delta = max(delta, 10.0) }
                if normalizedGeneric == normalizedQuery { delta = max(delta, 9.0) }
                if normalizedName == normalizedQuery { delta = max(delta, 8.5) }
                if normalizedKana == normalizedQuery { delta = max(delta, 7.5) }
                if normalizedImprints.contains(normalizedQuery) { delta = max(delta, 10.5) }

                if normalizedBrand.contains(normalizedQuery) || normalizedQuery.contains(normalizedBrand) { delta = max(delta, 6.5) }
                if normalizedGeneric.contains(normalizedQuery) || normalizedQuery.contains(normalizedGeneric) { delta = max(delta, 5.8) }
                if normalizedName.contains(normalizedQuery) || normalizedQuery.contains(normalizedName) { delta = max(delta, 5.2) }
                if normalizedKana.contains(normalizedQuery) || normalizedQuery.contains(normalizedKana) { delta = max(delta, 4.4) }
                if normalizedImprints.contains(where: { $0.contains(normalizedQuery) || normalizedQuery.contains($0) }) {
                    delta = max(delta, 7.0)
                }

                if delta > 0 {
                    var entry = scored[med.id] ?? (med, 0, [])
                    entry.score = max(entry.score, delta)
                    entry.matched.insert(query)
                    scored[med.id] = entry
                }
            }
        }

        return scored.values
            .map { MedicineMatch(medicine: $0.medicine, score: $0.score, matchedKeywords: Array($0.matched).sorted()) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.medicine.brandName < rhs.medicine.brandName
                }
                return lhs.score > rhs.score
            }
    }

    private static func searchRemoteMedicines(using queries: [String]) async -> [MedicineMatch] {
        let candidates = Array(queries.filter(shouldUseForRemoteSearch(_:)).prefix(3))
        guard !candidates.isEmpty else { return [] }

        // 逐次アクセスは待ち時間が長くなるため候補クエリを並列で照会し、
        // 応答の遅いクエリはタイムアウトで打ち切る
        let fetched = await withTaskGroup(of: (index: Int, query: String, medicine: Medicine)?.self) { group in
            for (index, query) in candidates.enumerated() {
                group.addTask {
                    guard let medicine = try? await withTimeout(seconds: 12, operation: {
                        try await PMDAService.fetchTemporaryMedicine(named: query)
                    }) else { return nil }
                    return (index, query, medicine)
                }
            }

            var results: [(index: Int, query: String, medicine: Medicine)] = []
            for await value in group {
                if let value { results.append(value) }
            }
            return results
        }

        var matches: [MedicineMatch] = []
        var seen: Set<String> = []
        for entry in fetched.sorted(by: { $0.index < $1.index }) {
            let dedupeKey = normalizeToken(entry.medicine.brandName + entry.medicine.genericName)
            guard !dedupeKey.isEmpty, seen.insert(dedupeKey).inserted else { continue }
            matches.append(
                MedicineMatch(
                    medicine: entry.medicine,
                    score: max(5.5, 9.0 - Double(entry.index)),
                    matchedKeywords: [entry.query]
                )
            )
        }
        return matches
    }

    private static func withTimeout<T: Sendable>(
        seconds: Double,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            group.cancelAll()
            return result
        }
    }

    private static func mergeMatches(primary: [MedicineMatch], secondary: [MedicineMatch]) -> [MedicineMatch] {
        var results: [MedicineMatch] = []
        var seen: Set<String> = []

        for match in primary + secondary {
            let key = normalizeToken(match.medicine.brandName + match.medicine.genericName)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            results.append(match)
        }

        return Array(results.prefix(5))
    }

    private static func categoryKeywords(_ cat: String) -> [String] {
        if cat.contains("解熱")          { return ["nsaid","鎮痛","解熱","loxoprofen","ロキソ"] }
        if cat.contains("カルシウム")    { return ["降圧","血圧","ccb","amlodipine","アムロ"] }
        if cat.contains("ヒスタミン")    { return ["アレルギー","花粉","cetirizine","セチリ","antihistamine"] }
        if cat.contains("プロトンポンプ") { return ["胃酸","ppi","omeprazole","オメプラ","胃潰瘍","逆流"] }
        return []
    }

    private static func normalizeToken(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "「", with: "")
            .replacingOccurrences(of: "」", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "（", with: "")
            .replacingOccurrences(of: "）", with: "")
    }

    private static func searchTokens(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: " 　,，.．・/／\\|:：;；()（）[]【】「」-−ー")
        let split = text.components(separatedBy: separators).filter { !$0.isEmpty }
        return split + [text]
    }

    private static func prioritizedQueries(texts: [String], barcodes: [String]) -> [String] {
        let rawCandidates = (texts + barcodes).flatMap(searchTokens(from:))
        var seen: Set<String> = []

        return rawCandidates
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { queryPriority($0) > queryPriority($1) }
            .filter { candidate in
                let normalized = normalizeToken(candidate)
                guard !normalized.isEmpty, !seen.contains(normalized) else { return false }
                seen.insert(normalized)
                return true
            }
    }

    private static func queryPriority(_ query: String) -> Int {
        let normalized = normalizeToken(query)
        guard !normalized.isEmpty else { return 0 }

        var score = min(normalized.count, 20)
        if query.range(of: #"\d+(mg|μg|g|mL|ml|%)"#, options: .regularExpression) != nil { score += 20 }
        if query.contains("錠") || query.contains("カプセル") || query.contains("細粒") || query.contains("テープ") || query.contains("シロップ") {
            score += 18
        }
        if query.range(of: #"(?i)[A-Z]{1,4}[- ]?\d{1,4}[A-Z]?$"#, options: .regularExpression) != nil { score += 22 }
        if query.range(of: #"(?i)^[A-Z0-9-]{3,}$"#, options: .regularExpression) != nil { score += 16 }
        if query.range(of: #"[ァ-ヶー]{2,}"#, options: .regularExpression) != nil { score += 12 }
        if query.range(of: #"^\d{8,13}$"#, options: .regularExpression) != nil { score += 10 }
        if query.count <= 1 { score = 0 }
        return score
    }

    private static func shouldUseForRemoteSearch(_ query: String) -> Bool {
        if query.count < 2 || query.count > 40 { return false }
        if query.range(of: #"[ぁ-んァ-ヶ一-龠A-Za-z0-9]"#, options: .regularExpression) == nil { return false }
        return true
    }

    private static func isMedicineSearchQuery(_ query: String) -> Bool {
        if !shouldUseForRemoteSearch(query) { return false }
        if query.range(of: #"[ァ-ヶー]{3,}"#, options: .regularExpression) != nil { return true }
        if query.range(of: #"[ぁ-ん]{3,}"#, options: .regularExpression) != nil { return true }
        if query.range(of: #"[A-Za-z]{4,}"#, options: .regularExpression) != nil { return true }
        if query.range(of: #"(?i)[A-Z]{1,4}[- ]?\d{1,4}[A-Z]?$"#, options: .regularExpression) != nil { return true }
        if query.range(of: #"(?i)^[A-Z0-9-]{3,}$"#, options: .regularExpression) != nil { return true }
        if query.range(of: #"\d+(mg|μg|g|mL|ml|%)"#, options: .regularExpression) != nil { return true }
        if query.contains("錠") || query.contains("カプセル") || query.contains("細粒") || query.contains("散") || query.contains("テープ") {
            return true
        }
        return false
    }

    private static func isMedicineNameCandidate(_ query: String) -> Bool {
        if query.range(of: #"[ァ-ヶー]{3,}"#, options: .regularExpression) != nil { return true }
        if query.range(of: #"[ぁ-ん]{3,}"#, options: .regularExpression) != nil { return true }
        if query.contains("錠") || query.contains("カプセル") || query.contains("細粒") || query.contains("シート") {
            return true
        }
        if query.range(of: #"\d+(mg|μg|g|mL|ml|%)"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }
}

// MARK: - ImageSearchView

struct ImageSearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var analyzing = false
    @State private var result: AnalysisResult? = nil
    @State private var showCamera = false
    @State private var selectedMed: Medicine? = nil
    @State private var searchingDetectedText: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // ── 画像取得ボタン ─────────────────────────
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            PickerButton(icon: "photo.on.rectangle", label: "ライブラリから選択")
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    selectedImage = img
                                    result = nil
                                }
                            }
                        }

                        Button { showCamera = true } label: {
                            PickerButton(icon: "camera", label: "カメラで撮影")
                        }
                        .foregroundColor(.primary)
                    }

                    // 動作説明
                    InfoBanner()

                    // ── プレビュー + 解析ボタン ────────────────
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.15), radius: 6)

                        Button {
                            Task { await runAnalysis(img) }
                        } label: {
                            HStack(spacing: 8) {
                                if analyzing {
                                    ProgressView().tint(.white)
                                    Text("解析中...").fontWeight(.bold)
                                } else {
                                    Image(systemName: "sparkles.rectangle.stack")
                                    Text("この画像を解析する").fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(analyzing ? Color(.systemGray4) : Color.appTeal)
                            .foregroundColor(analyzing ? .secondary : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(analyzing)
                    }

                    // ── 解析結果 ──────────────────────────────
                    if let r = result {
                        ResultView(
                            result: r,
                            selectedMed: $selectedMed,
                            searchingText: searchingDetectedText,
                            onSearchText: { text in
                                Task { await runDetectedTextSearch(text) }
                            }
                        )
                    }

                    // ── 初期ガイダンス ────────────────────────
                    if selectedImage == nil {
                        EmptyGuide()
                    }

                    DisclaimerBox()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("📷 画像検索")
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage, onCapture: { result = nil })
            }
            .sheet(item: $selectedMed) { med in
                MedicineDetailView(medicine: med)
            }
        }
    }

    private func runAnalysis(_ image: UIImage) async {
        analyzing = true
        searchingDetectedText = nil
        result = await MedicineAnalyzer.analyze(image: image)
        analyzing = false
    }

    private func runDetectedTextSearch(_ text: String) async {
        guard let current = result else { return }
        searchingDetectedText = text
        result = await MedicineAnalyzer.searchDetectedText(text, preserving: current)
        searchingDetectedText = nil
    }
}

// MARK: - Sub Views

private struct PickerButton: View {
    let icon: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2)
            Text(label).font(.caption).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct InfoBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wand.and.stars").foregroundColor(.appTeal).font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text("オンデバイスAI解析").font(.caption).fontWeight(.bold)
                Text("端末内の文字認識（OCR）＋バーコード検出でAPIキー不要で動作します。パッケージや説明書の文字が写っていると精度が上がります。")
                    .font(.caption2).foregroundColor(.secondary).lineSpacing(3)
            }
        }
        .padding(12)
        .background(Color.appTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appTeal.opacity(0.3), lineWidth: 1))
    }
}

private struct EmptyGuide: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("薬の画像を選択してください").font(.headline).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                GuideRow(icon: "📦", text: "パッケージ・外箱を撮影")
                GuideRow(icon: "💊", text: "PTPシート（錠剤シート）を撮影")
                GuideRow(icon: "📄", text: "添付文書や説明書を撮影")
                GuideRow(icon: "🔖", text: "バーコードを撮影（自動検出）")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 10)
    }
}

private struct GuideRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

private struct DetectedTextButton: View {
    let text: String
    let systemImage: String
    let isSearching: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.65)
                } else {
                    Image(systemName: systemImage)
                        .font(.caption2)
                }
                Text(text)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundColor(tint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isSearching)
    }
}

// MARK: - ResultView

private struct ResultView: View {
    let result: AnalysisResult
    @Binding var selectedMed: Medicine?
    let searchingText: String?
    let onSearchText: (String) -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // 検出テキスト
            if !result.detectedTexts.isEmpty || !result.barcodes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("検出された文字・コード", systemImage: "text.magnifyingglass")
                        .font(.caption).fontWeight(.bold).foregroundColor(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(result.detectedTexts, id: \.self) { text in
                            DetectedTextButton(
                                text: text,
                                systemImage: "magnifyingglass",
                                isSearching: searchingText == text,
                                tint: .appBlue,
                                action: { onSearchText(text) }
                            )
                        }
                        ForEach(result.barcodes, id: \.self) { code in
                            DetectedTextButton(
                                text: code,
                                systemImage: "barcode",
                                isSearching: searchingText == code,
                                tint: .appIndigo,
                                action: { onSearchText(code) }
                            )
                        }
                    }

                    Text("文字をタップすると、その文字情報で薬剤検索します。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // マッチ結果
            if result.matches.isEmpty {
                NoMatchView(hasText: !result.detectedTexts.isEmpty)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Label("薬品データベースの照合結果", systemImage: "cross.case.fill")
                        .font(.caption).fontWeight(.bold).foregroundColor(.secondary)

                    ForEach(result.matches.prefix(3)) { match in
                        MatchRow(match: match)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedMed = match.medicine }
                    }
                }
            }
        }
    }
}

private struct MatchRow: View {
    @EnvironmentObject var appState: AppState
    let match: MedicineMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(match.medicine.brandName).font(.headline)
                        RxBadge(rx: match.medicine.rx)
                    }
                    Text(match.medicine.name).font(.caption).foregroundColor(.secondary)
                    Text(match.medicine.category)
                        .font(.caption2)
                        .foregroundColor(match.confidenceColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.confidenceLabel)
                        .font(.caption2).fontWeight(.bold)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(match.confidenceColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    Button {
                        appState.toggleMed(match.medicine)
                    } label: {
                        Image(systemName: appState.favMedicines.contains(match.medicine.id) ? "heart.fill" : "heart")
                            .foregroundColor(appState.favMedicines.contains(match.medicine.id) ? .appPink : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !match.matchedKeywords.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundColor(.appGreen)
                    Text("一致: \(match.matchedKeywords.prefix(4).joined(separator: "・"))")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            HStack {
                Text("タップして詳細を見る")
                    .font(.caption2).foregroundColor(.appBlue)
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(match.confidenceColor.opacity(0.3), lineWidth: 1))
    }
}

private struct NoMatchView: View {
    let hasText: Bool
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "questionmark.circle").font(.title).foregroundColor(.secondary)
            Text("データベースに一致する薬が見つかりませんでした")
                .font(.subheadline).multilineTextAlignment(.center).foregroundColor(.secondary)
            if hasText {
                Text("上の検出文字をタップすると、その文字で再検索できます。")
                    .font(.caption).multilineTextAlignment(.center).foregroundColor(.secondary)
            } else {
                Text("パッケージや説明書など薬の名前が印刷されている部分を撮影してください。")
                    .font(.caption).multilineTextAlignment(.center).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - CameraView

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onCapture: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate   = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ p: CameraView) { self.parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.onCapture?()
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - ApiKeySheet（後方互換のため残す）
struct ApiKeySheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section(footer: Text("現在の画像検索はオンデバイス（APIキー不要）で動作します。")) {
                    Text("APIキーは現在不要です").foregroundColor(.secondary)
                }
            }
            .navigationTitle("APIキー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 飲み合わせチェッカー

struct InteractionFinding: Identifiable {
    let id = UUID()
    let pairLabel: String
    let severity: String
    let title: String
    let detail: String
    let advice: String
}

enum InteractionChecker {
    /// 選択された薬のすべての組み合わせをチェックし、重い順に返す
    static func check(_ medicines: [Medicine]) -> [InteractionFinding] {
        var findings: [InteractionFinding] = []
        for i in medicines.indices {
            for j in medicines.indices where j > i {
                findings += check(medicines[i], medicines[j])
            }
        }
        return dedup(findings).sorted { severityRank($0.severity) < severityRank($1.severity) }
    }

    static func severityRank(_ severity: String) -> Int {
        switch severity {
        case "禁忌": return 0
        case "重大": return 1
        case "中等度": return 2
        case "注意": return 3
        case "軽度": return 4
        default: return 5
        }
    }

    private static func check(_ a: Medicine, _ b: Medicine) -> [InteractionFinding] {
        var findings: [InteractionFinding] = []
        let pair = "\(a.brandName) × \(b.brandName)"

        // 1. 同じ有効成分の重複（気づきにくく危険度が高い）
        if sameIngredient(a, b) {
            findings.append(.init(
                pairLabel: pair,
                severity: "重大",
                title: "同じ成分の重複",
                detail: "どちらも有効成分が「\(a.genericName)」の薬です。両方を一緒に飲むと効きすぎや副作用のリスクが高まります。",
                advice: "同じ成分の薬を重ねて飲まないでください。別々の病院・薬局でもらった薬の場合は、必ず医師・薬剤師に伝えてください。"
            ))
        } else if sameCategory(a, b) {
            // 2. 同じ分類の薬の重複
            findings.append(.init(
                pairLabel: pair,
                severity: "注意",
                title: "同じ分類の薬の重複",
                detail: "どちらも「\(a.category)」に分類される薬です。似た作用が重なる可能性があります。",
                advice: "2つを併用してよいか、医師・薬剤師に確認してください。"
            ))
        }

        // 3. 登録済みの相互作用データと照合（双方向）
        findings += registeredFindings(of: a, against: b, pair: pair)
        findings += registeredFindings(of: b, against: a, pair: pair)

        // 4. 注意文言に相手の薬の名前が含まれていないか
        findings += textFindings(of: a, against: b, pair: pair)
        findings += textFindings(of: b, against: a, pair: pair)

        return findings
    }

    private static func registeredFindings(of a: Medicine, against b: Medicine, pair: String) -> [InteractionFinding] {
        a.interactions.compactMap { interaction in
            guard matches(interaction.drug, medicine: b) else { return nil }
            return InteractionFinding(
                pairLabel: pair,
                severity: interaction.severity,
                title: "\(a.brandName) の相互作用情報: \(interaction.drug)",
                detail: interaction.mechanism,
                advice: interaction.action
            )
        }
    }

    /// 相互作用の相手（薬名または分類名）が指定の薬に該当するか
    private static func matches(_ interactionDrug: String, medicine: Medicine) -> Bool {
        let target = normalize(interactionDrug)
        guard !target.isEmpty else { return false }

        // 薬名での一致
        let names = [medicine.brandName, medicine.genericName, medicine.name, medicine.kana]
            .map(normalize)
            .filter { $0.count >= 3 }
        if names.contains(where: { target.contains($0) || $0.contains(target) }) {
            return true
        }

        // 分類名での一致（例: 「ACE阻害薬・ARB」 と category「ARB」）
        let category = normalize(medicine.category)
        if category.count >= 2, target.contains(category) {
            return true
        }

        // タグでの一致
        if medicine.tags.map(normalize).contains(where: { $0.count >= 3 && target.contains($0) }) {
            return true
        }

        return false
    }

    private static func textFindings(of a: Medicine, against b: Medicine, pair: String) -> [InteractionFinding] {
        let combined = normalize(
            ([a.general.interactionWarning] + a.pro.contraindications + a.pro.monitoring)
                .joined(separator: "\n")
        )
        guard !combined.isEmpty else { return [] }

        let bNames = [b.brandName, b.genericName, b.name]
            .map(normalize)
            .filter { $0.count >= 3 }
        guard bNames.contains(where: { combined.contains($0) }) else { return [] }

        return [InteractionFinding(
            pairLabel: pair,
            severity: "注意",
            title: "\(a.brandName) の注意書きに関連する記載",
            detail: "\(a.brandName)の注意文の中に、\(b.brandName)（またはその成分名）に関する記載があります。",
            advice: "\(a.brandName)の詳細ページや添付文書で内容を確認し、薬剤師に相談してください。"
        )]
    }

    private static func sameIngredient(_ a: Medicine, _ b: Medicine) -> Bool {
        let ga = normalize(a.genericName)
        let gb = normalize(b.genericName)
        guard ga.count >= 3, gb.count >= 3 else { return false }
        return ga == gb || ga.contains(gb) || gb.contains(ga)
    }

    private static func sameCategory(_ a: Medicine, _ b: Medicine) -> Bool {
        let ca = normalize(a.category)
        let cb = normalize(b.category)
        guard !ca.isEmpty, ca == cb else { return false }
        // 情報の少ない汎用カテゴリは重複判定に使わない
        let generic = ["医薬品", "医療用医薬品", "一般用医薬品"].map(normalize)
        return !generic.contains(ca)
    }

    private static func dedup(_ findings: [InteractionFinding]) -> [InteractionFinding] {
        var seen: Set<String> = []
        return findings.filter { finding in
            let key = [finding.pairLabel, finding.severity, normalize(finding.title)].joined(separator: "|")
            return seen.insert(key).inserted
        }
    }

    private static func normalize(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: #"[\s（）()「」・,、]"#, with: "", options: .regularExpression)
            .lowercased()
    }
}

// MARK: - InteractionCheckerView

struct InteractionCheckerView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var medicineRepository = MedicineRepository.shared
    @State private var selected: [Medicine] = []
    @State private var query = ""
    @State private var showPhotoSheet = false
    @FocusState private var searchFocused: Bool

    private let maxCount = 3

    private var suggestions: [Medicine] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let selectedIDs = Set(selected.map(\.id))
        return medicineRepository.searchResults(for: trimmed).medicines
            .filter { !selectedIDs.contains($0.id) }
            .prefix(6)
            .map { $0 }
    }

    private var findings: [InteractionFinding] {
        selected.count >= 2 ? InteractionChecker.check(selected) : []
    }

    private var overallBanner: (label: String, note: String, color: Color, icon: String) {
        if findings.contains(where: { ["禁忌", "重大"].contains($0.severity) }) {
            return ("危険な飲み合わせの可能性があります",
                    "自己判断で併用せず、必ず医師・薬剤師に相談してください。",
                    .appRed, "exclamationmark.octagon.fill")
        }
        if !findings.isEmpty {
            return ("注意が必要な飲み合わせがあります",
                    "下の内容を確認し、心配な点は薬剤師に相談してください。",
                    .appOrange, "exclamationmark.triangle.fill")
        }
        return ("登録データでは問題は見つかりませんでした",
                "すべての飲み合わせを網羅しているわけではありません。お薬手帳を持って薬剤師にご確認ください。",
                .appGreen, "checkmark.seal.fill")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // ── 説明バナー ─────────────────────────
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "pills.circle.fill")
                            .foregroundColor(.appOrange).font(.title3)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("のみ合わせをチェックします").font(.caption).fontWeight(.bold)
                            Text("2〜3種類の薬を選ぶと、成分の重複や登録されている相互作用情報を照合して警告します。写真からの追加もできます。")
                                .font(.caption2).foregroundColor(.secondary).lineSpacing(3)
                        }
                    }
                    .padding(12)
                    .background(Color.appOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appOrange.opacity(0.3), lineWidth: 1))

                    // ── 選択済みの薬 ────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("チェックする薬（\(selected.count)/\(maxCount)）", systemImage: "checklist")
                            .font(.caption).fontWeight(.bold).foregroundColor(.secondary)

                        if selected.isEmpty {
                            Text("下の検索欄または「写真から追加」で薬を選んでください。")
                                .font(.caption).foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }

                        ForEach(Array(selected.enumerated()), id: \.element.id) { index, med in
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(Color.appTeal))
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(med.brandName).font(.subheadline).fontWeight(.semibold)
                                        RxBadge(rx: med.rx)
                                    }
                                    Text(med.name).font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    selected.removeAll { $0.id == med.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.systemGray3))
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // ── 薬の追加 ────────────────────────────
                    if selected.count < maxCount {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                                TextField("薬の名前で検索して追加", text: $query)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($searchFocused)
                                if !query.isEmpty {
                                    Button { query = "" } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            ForEach(suggestions) { med in
                                Button {
                                    selected.append(med)
                                    query = ""
                                    searchFocused = false
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.appTeal)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(med.brandName).font(.subheadline)
                                            Text(med.name).font(.caption2).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        RxBadge(rx: med.rx)
                                    }
                                    .padding(10)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                searchFocused = false
                                showPhotoSheet = true
                            } label: {
                                Label("写真から追加（パッケージやシートを撮影）", systemImage: "camera.viewfinder")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.appTeal.opacity(0.12))
                                    .foregroundColor(.appTeal)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    // ── 判定結果 ────────────────────────────
                    if selected.count >= 2 {
                        let banner = overallBanner
                        VStack(alignment: .leading, spacing: 8) {
                            Label(banner.label, systemImage: banner.icon)
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundColor(banner.color)
                            Text(banner.note)
                                .font(.caption).foregroundColor(.appTextSecondary).lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(banner.color.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(banner.color.opacity(0.4), lineWidth: 1))

                        ForEach(findings) { finding in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(finding.pairLabel)
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundColor(.appTextSecondary)
                                    Spacer()
                                    SeverityBadge(severity: finding.severity)
                                }
                                Text(finding.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                Text(finding.detail)
                                    .font(.caption).foregroundColor(.appTextSecondary).lineSpacing(3)
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption2).foregroundColor(.appBlue)
                                        .padding(.top, 2)
                                    Text(finding.advice)
                                        .font(.caption).foregroundColor(.appBlue).lineSpacing(3)
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.interactionColor(finding.severity).opacity(0.35), lineWidth: 1)
                            )
                        }
                    } else if selected.count == 1 {
                        Text("もう1種類以上追加するとチェックできます。")
                            .font(.caption).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }

                    DisclaimerBox()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("💊 のみ合わせ")
            .sheet(isPresented: $showPhotoSheet) {
                CheckerPhotoSheet { medicine in
                    if !selected.contains(where: { $0.id == medicine.id }), selected.count < maxCount {
                        selected.append(medicine)
                    }
                }
            }
        }
    }
}

// MARK: - CheckerPhotoSheet（写真から薬を追加）

private struct CheckerPhotoSheet: View {
    let onPick: (Medicine) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil
    @State private var showCamera = false
    @State private var analyzing = false
    @State private var matches: [MedicineMatch] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            PickerButton(icon: "photo.on.rectangle", label: "ライブラリから選択")
                        }
                        Button { showCamera = true } label: {
                            PickerButton(icon: "camera", label: "カメラで撮影")
                        }
                        .foregroundColor(.primary)
                    }

                    if let image {
                        Image(uiImage: image)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if analyzing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("解析中...").font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    if !matches.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("見つかった薬（タップして追加）", systemImage: "checkmark.seal.fill")
                                .font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                            ForEach(matches.prefix(5)) { match in
                                Button {
                                    onPick(match.medicine)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill").foregroundColor(.appTeal)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(match.medicine.brandName).font(.subheadline)
                                            Text(match.medicine.name).font(.caption2).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(match.confidenceLabel)
                                            .font(.caption2).fontWeight(.bold)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(match.confidenceColor.opacity(0.15))
                                            .foregroundColor(match.confidenceColor)
                                            .clipShape(Capsule())
                                    }
                                    .padding(10)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else if image != nil && !analyzing {
                        Text("薬を特定できませんでした。名前が写るように撮り直してみてください。")
                            .font(.caption).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("写真から薬を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        image = img
                    }
                }
            }
            .onChange(of: image) { _, img in
                guard let img else { return }
                Task { await analyze(img) }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $image, onCapture: {})
            }
        }
    }

    private func analyze(_ img: UIImage) async {
        analyzing = true
        matches = []
        let result = await MedicineAnalyzer.analyze(image: img)
        matches = result.matches
        analyzing = false
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:            self = .up
        case .upMirrored:    self = .upMirrored
        case .down:          self = .down
        case .downMirrored:  self = .downMirrored
        case .left:          self = .left
        case .leftMirrored:  self = .leftMirrored
        case .right:         self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}

private extension Array where Element == String {
    func deduplicatedByNormalizedToken() -> [String] {
        var seen: Set<String> = []
        return filter { value in
            let normalized = value
                .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
                .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            guard !normalized.isEmpty, !seen.contains(normalized) else { return false }
            seen.insert(normalized)
            return true
        }
    }
}
