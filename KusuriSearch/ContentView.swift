import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0

    // タブバー高さ（コンテンツの下余白計算用）
    static let tabBarHeight: CGFloat = 68

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── タブコンテンツ ──
            // .page スタイルは横スクロールと干渉するため使わない
            // selection バインドで programmatic な切り替えのみ行う
            TabView(selection: $selectedTab) {
                SearchView()
                    .tag(0)
                    .safeAreaInset(edge: .bottom) { bottomInset }

                ImageSearchView()
                    .tag(1)
                    .safeAreaInset(edge: .bottom) { bottomInset }

                InteractionCheckerView()
                    .tag(2)
                    .safeAreaInset(edge: .bottom) { bottomInset }

                PharmacyView()
                    .tag(3)
                    .safeAreaInset(edge: .bottom) { bottomInset }

                ManufacturerView()
                    .tag(4)
                    .safeAreaInset(edge: .bottom) { bottomInset }

                FavoritesView()
                    .tag(5)
                    .safeAreaInset(edge: .bottom) { bottomInset }
            }
            // tabItem を残しながらバーを非表示にする
            .toolbar(.hidden, for: .tabBar)

            // ── カスタムタブバー ──
            FriendlyTabBar(selectedTab: $selectedTab, favCount: appState.totalFavCount)
        }
        .environmentObject(appState)
        .preferredColorScheme(appState.themeMode.colorScheme)
        .tint(Color.appPink)
        .ignoresSafeArea(.keyboard)
    }

    /// タブバー分の透明余白（コンテンツが隠れないように）
    private var bottomInset: some View {
        Color.clear.frame(height: Self.tabBarHeight)
    }
}

// MARK: - FriendlyTabBar
struct FriendlyTabBar: View {
    @Binding var selectedTab: Int
    let favCount: Int
    @Environment(\.colorScheme) private var colorScheme

    private let items: [(icon: String, activeIcon: String, label: String)] = [
        ("magnifyingglass",          "magnifyingglass",              "薬を調べる"),
        ("camera",                   "camera.fill",                  "画像検索"),
        ("pills.circle",             "pills.circle.fill",            "のみ合わせ"),
        ("mappin.and.ellipse",       "mappin.and.ellipse",           "薬局を探す"),
        ("building.2",               "building.2.fill",              "メーカー"),
        ("heart",                    "heart.fill",                   "お気に入り")
    ]

    private let activeColors: [Color] = [
        .appPink, .appTeal, .appOrange, .appPurple, .appIndigo, .appPink
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                tabItem(index: index)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.06)
                              : Color.white.opacity(0.4))
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: -4)
                // ホームインジケーター領域まで背景を伸ばし、
                // バー下に隙間ができてタップが背後のコンテンツへ抜けるのを防ぐ
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }

    @ViewBuilder
    private func tabItem(index: Int) -> some View {
        let item = items[index]
        let isSelected = selectedTab == index
        let color = activeColors[index]

        Button {
            // withAnimation で selection を変えると TabView 側の切替と干渉して
            // 表示が乱れるため、選択は即時反映しインジケーターのみアニメーションする
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // 選択インジケーター
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }

                    ZStack(alignment: .topTrailing) {
                        Image(systemName: isSelected ? item.activeIcon : item.icon)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? color : .secondary)
                            .frame(width: 44, height: 32)
                            .scaleEffect(isSelected ? 1.1 : 1.0)

                        // バッジ（お気に入り）
                        if index == items.count - 1 && favCount > 0 {
                            Text("\(min(favCount, 99))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 14, minHeight: 14)
                                .padding(.horizontal, 3)
                                .background(Color.appPink)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }
                }

                Text(item.label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? color : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
