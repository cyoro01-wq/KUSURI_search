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
        case "軽度": return .appYellow
        case "禁忌": return Color(hex: "8B0000")
        default: return .secondary
        }
    }
}

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

// MARK: - RxBadge
struct RxBadge: View {
    let rx: Bool
    var body: some View {
        Text(rx ? "Rx" : "OTC")
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(rx ? Color.appRed : Color.appGreen)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 5))
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

struct BrandHeaderCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            KusurinLogoMark()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "232938").opacity(0.92) : Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10), radius: 18, x: 0, y: 10)
    }
}

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

struct KusurinLogoMark: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFF2F7"), Color(hex: "FFF7E8"), Color(hex: "EEF5FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)

                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 54, height: 54)

                Capsule()
                    .fill(Color.appPink)
                    .frame(width: 18, height: 34)
                    .offset(x: -6)

                Capsule()
                    .fill(Color(hex: "FFD66F"))
                    .frame(width: 18, height: 34)
                    .offset(x: 6)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 5, height: 30)

                Circle()
                    .fill(Color(hex: "FFE8F1"))
                    .frame(width: 14, height: 14)
                    .offset(x: 18, y: 18)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color.appPink)
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            )

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
