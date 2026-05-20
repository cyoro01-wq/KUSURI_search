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

                    // ── ヘッダー ──────────────────────────────────
                    SearchHeaderView()
                        .contentShape(Rectangle())
                        .onTapGesture { searchFieldFocused = false }

                    // ── フィルターエリア ──────────────────────────
                    VStack(spacing: 10) {

                        // 検索バー
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(searchFieldFocused ? Color.appPink : Color.secondary)
                                .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)

                            TextField("薬品名・成分名・症状で検索", text: $query)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($searchFieldFocused)
                                .font(.system(.body, design: .rounded))

                            if !query.isEmpty {
                                Button {
                                    withAnimation { query = "" }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(colorScheme == .dark
                                      ? Color(hex: "252B38").opacity(0.96)
                                      : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    searchFieldFocused
                                        ? Color.appPink.opacity(0.5)
                                        : (colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E8EAF0")),
                                    lineWidth: searchFieldFocused ? 1.5 : 1
                                )
                        )
                        .shadow(
                            color: searchFieldFocused
                                ? Color.appPink.opacity(0.12)
                                : Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06),
                            radius: searchFieldFocused ? 14 : 8,
                            x: 0, y: 4
                        )
                        .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)

                        // カテゴリチップ
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    let color: Color = cat == "すべて" ? .appPink : categoryAccentColor(cat)
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            selectedCategory = cat
                                        }
                                        searchFieldFocused = false
                                    } label: {
                                        Text(cat)
                                            .font(.caption).fontWeight(.semibold)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(
                                                selectedCategory == cat
                                                    ? color
                                                    : (colorScheme == .dark
                                                       ? Color(hex: "262C39")
                                                       : Color.white.opacity(0.85))
                                            )
                                            .foregroundColor(selectedCategory == cat ? .white : .secondary)
                                            .clipShape(Capsule())
                                            .shadow(
                                                color: selectedCategory == cat ? color.opacity(0.3) : .clear,
                                                radius: 5, x: 0, y: 2
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 2).padding(.vertical, 2)
                        }

                        // Rx / OTC フィルター + 医療者モードトグル
                        HStack(spacing: 8) {
                            ForEach([("all","すべて", Color.appBlue),
                                     ("rx","Rx 処方薬", Color.appRed),
                                     ("otc","OTC 市販薬", Color.appGreen)],
                                    id: \.0) { val, label, color in
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        rxFilter = val
                                    }
                                    searchFieldFocused = false
                                } label: {
                                    Text(label)
                                        .font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(
                                            rxFilter == val
                                                ? color
                                                : (colorScheme == .dark
                                                   ? Color(hex: "262C39")
                                                   : Color.white.opacity(0.85))
                                        )
                                        .foregroundColor(rxFilter == val ? .white : .secondary)
                                        .clipShape(Capsule())
                                        .shadow(
                                            color: rxFilter == val ? color.opacity(0.3) : .clear,
                                            radius: 5, x: 0, y: 2
                                        )
                                }
                            }
                            Spacer()

                            // 医療者モードトグル（アイコン + スイッチ）
                            HStack(spacing: 4) {
                                Image(systemName: "cross.case.fill")
                                    .font(.caption2)
                                    .foregroundColor(appState.proMode ? .appIndigo : .secondary)
                                Toggle("", isOn: $appState.proMode)
                                    .toggleStyle(.switch)
                                    .tint(.appIndigo)
                                    .labelsHidden()
                                    .scaleEffect(0.78)
                                    .frame(width: 44)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(appState.proMode
                                          ? Color.appIndigo.opacity(0.1)
                                          : (colorScheme == .dark
                                             ? Color(hex: "262C39")
                                             : Color.white.opacity(0.85)))
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { searchFieldFocused = false }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .contentShape(Rectangle())
                    .onTapGesture { searchFieldFocused = false }

                    Divider().opacity(0.4)

                    // ── 結果 ──────────────────────────────────────
                    if filtered.isEmpty {
                        emptyStateView
                    } else {
                        resultListView
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .contentShape(Rectangle())
            .onTapGesture { searchFieldFocused = false }
            .sheet(item: $selectedMed) { med in
                MedicineDetailView(medicine: med)
            }
        }
    }

    // MARK: - 空の状態
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "該当する薬が見つかりません",
                systemImage: "pills.fill",
                description: Text(trimmedQuery.isEmpty
                    ? "検索条件を変更してみてください"
                    : "公開医薬品データベースから薬品名を自動検索できます。")
            )

            if !trimmedQuery.isEmpty {
                Button {
                    Task { await fetchFromRemoteDB() }
                } label: {
                    HStack(spacing: 8) {
                        if remoteLoading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkle.magnifyingglass")
                        }
                        Text(remoteLoading ? "検索中..." : "「\(trimmedQuery)」をデータベースで検索")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.appPink, Color.appIndigo],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.appPink.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .disabled(remoteLoading)

                if let remoteError {
                    Text(remoteError)
                        .font(.caption).foregroundColor(.appRed)
                        .multilineTextAlignment(.center).padding(.horizontal)
                } else if !remoteLoading {
                    Text("取得できた場合はここに詳細を表示します。")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { searchFieldFocused = false }
    }

    // MARK: - 結果リスト
    private var resultListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                HStack {
                    Text("\(filtered.count) 件")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                ForEach(filtered) { med in
                    FriendlyMedicineCard(med: med)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedMed = med }
                }

                Color.clear.frame(height: 20)
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded { searchFieldFocused = false }
        )
    }

    // MARK: - Helpers
    func categorySortKey(_ category: String) -> String {
        let priority = [
            "解熱鎮痛薬","解熱鎮痛消炎剤","鎮痛薬","鎮痛補助薬",
            "睡眠薬","抗不安薬","抗うつ薬","抗精神病薬",
            "糖尿病治療薬","インスリン製剤",
            "カルシウム拮抗薬","ARB","ACE阻害薬","β遮断薬","利尿薬",
            "脂質異常症治療薬","抗凝固薬","抗血小板薬",
            "抗菌薬","抗ウイルス薬",
            "抗ヒスタミン薬","抗喘息薬",
            "プロトンポンプ阻害薬（PPI）","P-CAB","H2受容体拮抗薬"
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

// MARK: - MedicineRow (後方互換エイリアス)
// FavoritesView / ImageSearchView 等から参照されるため残す
struct MedicineRow: View {
    @EnvironmentObject var appState: AppState
    let med: Medicine

    var body: some View {
        FriendlyMedicineCard(med: med)
    }
}
