import SwiftUI
import UIKit

// MARK: - Colors
extension Color {
    static let appBlue   = Color(hex: "3E79D8")
    static let appGreen  = Color(hex: "2F9B71")
    static let appRed    = Color(hex: "E4617C")
    static let appOrange = Color(hex: "D98A2F")
    static let appPurple = Color(hex: "8D67D6")
    static let appPink   = Color(hex: "D85D93")
    static let appTeal   = Color(hex: "278EA5")
    static let appIndigo = Color(hex: "5A71D6")
    static let appYellow = Color(hex: "D7A62E")
    static let appCream  = Color(hex: "FFF8EE")
    static let appLavender = Color(hex: "F4ECFF")
    static let appMint   = Color(hex: "EFFAF4")
    static let appCard   = Color.white.opacity(0.96)
    static let appTextPrimary = Color(hex: "2E3340")
    static let appTextSecondary = Color(hex: "5C6474")
    static let proBackgroundTop = Color(hex: "EEF4FF")
    static let proBackgroundBottom = Color(hex: "DCE8FF")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    static func interactionColor(_ severity: String) -> Color {
        switch severity {
        case "重大": return .appRed
        case "中等度": return .appOrange
        case "注意": return .appOrange
        case "軽度": return .appYellow
        case "禁忌": return Color(hex: "8B0000")
        default: return .secondary
        }
    }
}

// MARK: - SoftAppBackground
struct SoftAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: [
                colorScheme == .dark ? Color(hex: "171A22") : Color(hex: "FFF8F1"),
                colorScheme == .dark ? Color(hex: "1E1A28") : Color(hex: "FFE7F0"),
                colorScheme == .dark ? Color(hex: "16212F") : Color(hex: "E7F0FF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.35))
                    .frame(width: 240, height: 240)
                    .offset(x: -120, y: -280)
                Circle()
                    .fill(Color(hex: colorScheme == .dark ? "4E2A4B" : "FFD8EA").opacity(colorScheme == .dark ? 0.20 : 0.22))
                    .frame(width: 180, height: 180)
                    .offset(x: 140, y: -160)
                Circle()
                    .fill(Color(hex: colorScheme == .dark ? "23486C" : "CFE9FF").opacity(colorScheme == .dark ? 0.18 : 0.25))
                    .frame(width: 210, height: 210)
                    .offset(x: 160, y: 320)
            }
        )
        .ignoresSafeArea()
    }
}

// MARK: - RxBadge (v1.2 — アウトラインスタイル)
struct RxBadge: View {
    let rx: Bool
    var body: some View {
        Text(rx ? "Rx" : "OTC")
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(rx ? Color.appRed.opacity(0.10) : Color.appGreen.opacity(0.10))
            .foregroundColor(rx ? .appRed : .appGreen)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(rx ? Color.appRed.opacity(0.3) : Color.appGreen.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - SeverityBadge
struct SeverityBadge: View {
    let severity: String
    var body: some View {
        Text(severity)
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.interactionColor(severity).opacity(0.15))
            .foregroundColor(Color.interactionColor(severity))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - SectionBox
struct SectionBox<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 3, height: 16)
                Text(title)
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.appTextSecondary)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)
            Divider()
            content()
                .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "222734").opacity(0.96) : Color.appCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E2E7F0"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.06), radius: 16, x: 0, y: 10)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - DisclaimerBox
struct DisclaimerBox: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.appOrange).font(.caption)
            Text("この情報は参考情報です。正確な判断は医師・薬剤師にご確認ください。")
                .font(.caption).foregroundColor(.appTextSecondary)
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(hex: "352A1E") : Color(hex: "FFF5E8"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.appOrange.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - ProModeToggle
struct ProModeToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Picker("", selection: $isOn) {
            Label("一般向け", systemImage: "person").tag(false)
            Label("医療者向け", systemImage: "cross.case").tag(true)
        }
        .pickerStyle(.segmented)
        .tint(isOn ? .appIndigo : .appPink)
    }
}

// MARK: - SearchHeaderView (v1.2)
struct SearchHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // アプリアイコンと同じ「くすりん」キャラクター画像
            Image("KusurinIcon")
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.appPink.opacity(0.25), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 1) {
                Text("くすりん")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPink, Color.appIndigo],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                Text("やさしいおくすりガイド")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - BrandHeaderCard (後方互換)
struct BrandHeaderCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SearchHeaderView()
    }
}

// MARK: - ThemeModePicker
struct ThemeModePicker: View {
    @Binding var selection: AppThemeMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("表示モード", systemImage: "circle.lefthalf.filled")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)

            Picker("表示モード", selection: $selection) {
                ForEach(AppThemeMode.allCases, id: \.rawValue) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - FriendlyMedicineCard (v1.2 メインカードデザイン)
struct FriendlyMedicineCard: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let med: Medicine
    @State private var confirmRemoveFavorite = false

    var isFav: Bool { appState.favMedicines.contains(med.id) }

    var accentColor: Color {
        categoryAccentColor(med.category)
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左カラーアクセントバー
            LinearGradient(
                colors: [accentColor, accentColor.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: 4)
            .clipShape(
                RoundedRectangle(cornerRadius: 2)
            )
            .padding(.vertical, 16)
            .padding(.leading, 14)

            // コンテンツエリア
            HStack(alignment: .top, spacing: 12) {
                // 薬画像（あれば）
                if let photoURL = med.photoURL {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            EmptyView()
                        default:
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                ProgressView().scaleEffect(0.7)
                            }
                            .frame(width: 60, height: 60)
                        }
                    }
                }

                // テキスト情報
                VStack(alignment: .leading, spacing: 5) {
                    // 薬品名 + Rx/OTC
                    HStack(spacing: 6) {
                        Text(med.brandName)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(colorScheme == .dark ? .white : .appTextPrimary)
                            .lineLimit(1)
                        RxBadge(rx: med.rx)
                    }

                    // 一般名
                    if !med.name.isEmpty && med.name != med.brandName {
                        Text(med.name)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }

                    // カテゴリ
                    Text(med.category)
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(accentColor.opacity(0.12))
                        .foregroundColor(accentColor)
                        .clipShape(Capsule())

                    // 薬価（医療者モード）
                    if appState.proMode && med.pricing.brand.price > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "yensign.circle.fill")
                                .font(.caption2).foregroundColor(.appIndigo)
                            Text(String(format: "¥%.2f", med.pricing.brand.price))
                                .font(.caption2).fontWeight(.bold).foregroundColor(.appIndigo)
                            if let g = med.pricing.generics.first, g.price > 0 {
                                Text("→ GE ¥\(String(format: "%.2f", g.price))")
                                    .font(.caption2).foregroundColor(.appGreen)
                            }
                        }
                    }

                    // タグ
                    if !med.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(med.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2).foregroundColor(.secondary)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }

                Spacer(minLength: 4)

                // ハートボタン
                Button {
                    if isFav {
                        // 解除は誤タップの影響が大きいので確認を挟む
                        confirmRemoveFavorite = true
                    } else {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                            appState.toggleMed(med)
                        }
                    }
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundColor(isFav ? .appPink : Color(.systemGray3))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(isFav ? Color.appPink.opacity(0.12) : Color(.systemGray6))
                        )
                        .scaleEffect(isFav ? 1.05 : 1.0)
                        // HIG 推奨の 44pt タップ領域を確保（見た目は 34pt のまま）
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFav ? "お気に入りから削除" : "お気に入りに追加")
                .confirmationDialog(
                    "「\(med.brandName)」をお気に入りから削除しますか？",
                    isPresented: $confirmRemoveFavorite,
                    titleVisibility: .visible
                ) {
                    Button("削除する", role: .destructive) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                            appState.toggleMed(med)
                        }
                    }
                    Button("キャンセル", role: .cancel) {}
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(hex: "222734").opacity(0.95)
                        : (isFav ? Color.appPink.opacity(0.025) : Color.white)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isFav
                        ? Color.appPink.opacity(0.45)
                        : (colorScheme == .dark ? Color.white.opacity(0.07) : Color(hex: "ECEEF4")),
                    lineWidth: isFav ? 1.5 : 1
                )
        )
        .shadow(
            color: isFav
                ? Color.appPink.opacity(0.15)
                : Color.black.opacity(colorScheme == .dark ? 0.18 : 0.04),
            radius: isFav ? 12 : 6,
            x: 0, y: isFav ? 4 : 2
        )
    }
}

// MARK: - category accent color helper
func categoryAccentColor(_ category: String) -> Color {
    if category.contains("解熱") || category.contains("鎮痛") { return .appOrange }
    if category.contains("カルシウム") || category.contains("降圧") || category.contains("ARB") || category.contains("ACE") { return .appBlue }
    if category.contains("ヒスタミン") || category.contains("アレルギー") { return .appGreen }
    if category.contains("睡眠") || category.contains("抗不安") || category.contains("抗うつ") || category.contains("精神") { return .appPurple }
    if category.contains("糖尿病") || category.contains("インスリン") { return .appTeal }
    if category.contains("抗菌") || category.contains("抗ウイルス") { return .appRed }
    if category.contains("プロトンポンプ") || category.contains("胃") || category.contains("P-CAB") { return .appYellow }
    if category.contains("脂質") || category.contains("スタチン") { return .appIndigo }
    return .appIndigo
}

// MARK: - KusurinLogoMark
struct KusurinLogoMark: View {
    var body: some View {
        HStack(spacing: 12) {
            // アプリアイコンと同じ「くすりん」キャラクター画像
            Image("KusurinIcon")
                .resizable()
                .scaledToFill()
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Color.appPink.opacity(0.25), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("くすりん")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPink, Color.appPurple, Color.appIndigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("やさしいおくすりガイド")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.78))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Keyboard
extension View {
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}
