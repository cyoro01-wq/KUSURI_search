import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                SearchView()
                    .tag(0)

                ImageSearchView()
                    .tag(1)

                PharmacyView()
                    .tag(2)

                ManufacturerView()
                    .tag(3)

                FavoritesView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // カスタムタブバー
            FriendlyTabBar(selectedTab: $selectedTab, favCount: appState.totalFavCount)
        }
        .environmentObject(appState)
        .preferredColorScheme(appState.themeMode.colorScheme)
        .tint(Color.appPink)
        .ignoresSafeArea(.keyboard)
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
        ("mappin.and.ellipse",       "mappin.and.ellipse",           "薬局を探す"),
        ("building.2",               "building.2.fill",              "メーカー"),
        ("heart",                    "heart.fill",                   "お気に入り")
    ]

    private let activeColors: [Color] = [
        .appPink, .appTeal, .appPurple, .appIndigo, .appPink
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                tabItem(index: index)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, safeAreaBottom)
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
        )
    }

    @ViewBuilder
    private func tabItem(index: Int) -> some View {
        let item = items[index]
        let isSelected = selectedTab == index
        let color = activeColors[index]

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
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
                        if index == 4 && favCount > 0 {
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
        }
        .buttonStyle(.plain)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

#Preview {
    ContentView()
}
