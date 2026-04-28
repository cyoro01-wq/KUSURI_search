import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("薬を調べる", systemImage: "magnifyingglass") }

            ImageSearchView()
                .tabItem { Label("画像検索", systemImage: "camera") }

            PharmacyView()
                .tabItem { Label("薬局を探す", systemImage: "mappin.and.ellipse") }

            ManufacturerView()
                .tabItem { Label("メーカー", systemImage: "building.2") }

            FavoritesView()
                .tabItem { Label("お気に入り", systemImage: "heart.fill") }
                .badge(appState.totalFavCount)
        }
        .environmentObject(appState)
        .background(SoftAppBackground())
        .preferredColorScheme(appState.themeMode.colorScheme)
        .tint(Color.appPink)
    }
}

#Preview {
    ContentView()
}
