import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var medicineRepository = MedicineRepository.shared
    @State private var query = ""
    @State private var selectedCategory = "すべて"
    @State private var rxFilter = "all"
    @State private var selectedMed: Medicine? = nil
    @State private var remoteLoading = false
    @State private var remoteError: String?
    @FocusState private var searchFieldFocused: Bool

    var categories: [String] {
        let available = medicineRepository.allMedicines
            .map(\.category)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return ["すべて"] + Array(Set(available)).sorted { lhs, rhs in
            categorySortKey(lhs) < categorySortKey(rhs)
        }
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var filtered: [Medicine] {
        let q = trimmedQuery
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .lowercased()
        return medicineRepository.allMedicines.filter { m in
            let matchQ = q.isEmpty
                || medicineRepository.searchableText(for: m).contains(q)
            let matchC = selectedCategory == "すべて"
                || m.category == selectedCategory
            let matchR = rxFilter == "all"
                || (rxFilter == "rx" && m.rx)
                || (rxFilter == "otc" && !m.rx)
            return matchQ && matchC && matchR
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoftAppBackground()

                VStack(spacing: 0) {

                    // ── フィルター ──────────────────────────────────
                    VStack(spacing: 12) {
                        BrandHeaderCard()

                        // 検索バー
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.appPink)
                            TextField("薬品名・成分名・症状で検索", text: $query)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($searchFieldFocused)
                            if !query.isEmpty {
                                Button { query = "" } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            searchFieldFocused = false
                        }
                        .padding(14)
                        .background(colorScheme == .dark ? Color(hex: "252B38").opacity(0.96) : Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.9), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 12, x: 0, y: 8)

                        // カテゴリチップ
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button(cat) { selectedCategory = cat }
                                        .font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 13).padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.appBlue : (colorScheme == .dark ? Color(hex: "262C39") : Color.white.opacity(0.72)))
                                        .foregroundColor(selectedCategory == cat ? .white : .secondary)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                        .onTapGesture {
                            searchFieldFocused = false
                        }

                        // Rx / OTC チップ
                        HStack(spacing: 8) {
                            ForEach([("all","すべて"),("rx","Rx 処方薬"),("otc","OTC 市販薬")], id: \.0) { val, label in
                                Button(label) { rxFilter = val }
                                    .font(.caption).fontWeight(.medium)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(rxFilter == val ? rxColor(val) : (colorScheme == .dark ? Color(hex: "262C39") : Color.white.opacity(0.72)))
                                    .foregroundColor(rxFilter == val ? .white : .secondary)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            searchFieldFocused = false
                        }

                        // 医療者モードトグル
                        Toggle(isOn: $appState.proMode) {
                            Label("医療者モード（薬価を表示）", systemImage: "cross.case")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .toggleStyle(.switch)

                        ThemeModePicker(
                            selection: Binding(
                                get: { appState.themeMode },
                                set: { appState.setThemeMode($0) }
                            )
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        searchFieldFocused = false
                    }

                    Divider()

                    // ── 結果リスト ──────────────────────────────────
                    if filtered.isEmpty {
                        VStack(spacing: 14) {
                            ContentUnavailableView(
                                "該当する薬が見つかりません",
                                systemImage: "pills.fill",
                                description: Text(trimmedQuery.isEmpty ? "検索条件を変更してみてください" : "公開医薬品データベースから薬品名を自動検索できます。")
                            )

                            if !trimmedQuery.isEmpty {
                                Button {
                                    Task { await fetchFromRemoteDB() }
                                } label: {
                                    Label(remoteLoading ? "検索中..." : "データベースで「\(trimmedQuery)」を取得", systemImage: "sparkle.magnifyingglass")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(remoteLoading)

                                if let remoteError {
                                    Text(remoteError)
                                        .font(.caption)
                                        .foregroundColor(.appRed)
                                } else {
                                    Text("取得できた場合は、この画面から詳細欄へ反映して表示します。")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            searchFieldFocused = false
                        }
                    } else {
                        // ScrollView + LazyVStack で確実に展開
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { med in
                                    MedicineRow(med: med)
                                        .padding(.horizontal)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedMed = med }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                searchFieldFocused = false
                            }
                        )
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .contentShape(Rectangle())
            .onTapGesture {
                searchFieldFocused = false
            }
            .sheet(item: $selectedMed) { med in
                MedicineDetailView(medicine: med)
            }
        }
    }

    func rxColor(_ val: String) -> Color {
        switch val {
        case "rx":  return .appRed
        case "otc": return .appGreen
        default:    return .appBlue
        }
    }

    func categorySortKey(_ category: String) -> String {
        let priority = [
            "解熱鎮痛薬",
            "解熱鎮痛消炎剤",
            "鎮痛薬",
            "鎮痛補助薬",
            "睡眠薬",
            "抗不安薬",
            "抗うつ薬",
            "抗精神病薬",
            "糖尿病治療薬",
            "インスリン製剤",
            "カルシウム拮抗薬",
            "ARB",
            "ACE阻害薬",
            "β遮断薬",
            "利尿薬",
            "脂質異常症治療薬",
            "抗凝固薬",
            "抗血小板薬",
            "抗菌薬",
            "抗ウイルス薬",
            "抗ヒスタミン薬",
            "抗喘息薬",
            "プロトンポンプ阻害薬（PPI）",
            "P-CAB",
            "H2受容体拮抗薬"
        ]
        let index = priority.firstIndex(of: category) ?? 999
        return String(format: "%03d_%@", index, category)
    }

    func fetchFromRemoteDB() async {
        guard !trimmedQuery.isEmpty else { return }
        remoteLoading = true
        remoteError = nil
        defer { remoteLoading = false }

        do {
            let med = try await PMDAService.fetchTemporaryMedicine(named: trimmedQuery)
            selectedMed = med
        } catch {
            remoteError = error.localizedDescription
        }
    }
}

// MARK: - MedicineRow
struct MedicineRow: View {
    @EnvironmentObject var appState: AppState
    let med: Medicine

    var isFav: Bool { appState.favMedicines.contains(med.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                if let photoURL = med.photoURL {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 74, height: 74)
                                .padding(6)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            EmptyView()
                        default:
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                ProgressView()
                            }
                            .frame(width: 74, height: 74)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(med.brandName).font(.headline)
                                RxBadge(rx: med.rx)
                            }
                            Text(med.name).font(.caption).foregroundColor(.secondary)
                            Text(med.category)
                                .font(.caption)
                                .foregroundColor(categoryColor(med.category))
                        }
                        Spacer()
                        Button {
                            appState.toggleMed(med)
                        } label: {
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .foregroundColor(isFav ? .appPink : .secondary)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 薬価（医療者モード時）
            if appState.proMode {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("先発").font(.caption2).foregroundColor(.secondary)
                        if med.pricing.brand.price > 0 {
                            Text(String(format: "¥%.2f", med.pricing.brand.price))
                                .font(.caption).fontWeight(.semibold).foregroundColor(.appIndigo)
                        } else {
                            Text("未取得")
                                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        }
                    }
                    if let g = med.pricing.generics.first, g.price > 0 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("後発").font(.caption2).foregroundColor(.secondary)
                            Text(String(format: "¥%.2f", g.price))
                                .font(.caption).fontWeight(.semibold).foregroundColor(.appGreen)
                        }
                    }
                }
            }

            // タグ
            HStack(spacing: 5) {
                ForEach(med.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2).foregroundColor(.secondary)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .padding(14)
        .background(
            isFav ? Color.appPink.opacity(0.05)
                  : Color(.secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFav ? Color.appPink : Color.clear, lineWidth: 1.5)
        )
    }

    func categoryColor(_ cat: String) -> Color {
        if cat.contains("解熱")      { return .appOrange }
        if cat.contains("カルシウム") { return .appBlue   }
        if cat.contains("ヒスタミン") { return .appGreen  }
        return .appPurple
    }
}
