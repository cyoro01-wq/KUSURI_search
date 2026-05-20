import SwiftUI
import UIKit

private enum AppAppearance {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    static func configure() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = dynamicColor(
            light: UIColor(red: 1.0, green: 0.972, blue: 0.949, alpha: 0.96),
            dark: UIColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 0.96)
        )
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.appPink)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.appPink)]
        let normalColor = dynamicColor(
            light: UIColor(Color(hex: "8D8291")),
            dark: UIColor(red: 0.72, green: 0.74, blue: 0.78, alpha: 1.0)
        )
        tabAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        let titleColor = dynamicColor(
            light: UIColor(Color(hex: "6F5B6A")),
            dark: UIColor.white
        )
        navAppearance.titleTextAttributes = [.foregroundColor: titleColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}

@main
struct KusuriSearchApp: App {
    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
