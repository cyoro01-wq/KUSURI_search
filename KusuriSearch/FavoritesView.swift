import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var medicineRepository = MedicineRepository.shared
    @State private var segment = 0
    @State private var selectedMed: Medicine? = nil
    @Environment(\.colorScheme) private var colorScheme

    var favMedList: [Medicine] {
        medicineRepository.allMedicines.filter { appState.favMedicines.contains($0.id) }
    }
    var favPharmList: [Pharmacy] {
        appState.favoritePharmacyRecords
            .filter { appState.favPharmacies.contains($0.key) }
            .map(\.value)
            .sorted { ($0.distance ?? 9999) < ($1.distance ?? 9999) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoftAppBackground()

                VStack(spacing: 0) {
                    // ── グラデーションヘッダー ─────────────────────
                    favHeader

                    // ── セグメントタブ ────────────────────────────
                    HStack(spacing: 12) {
                        segmentButton(index: 0,
                                      icon: "pills.fill",
                                      label: "薬 (\(favMedList.count))",
                                      color: .appPink)
                        segmentButton(index: 1,
                                      icon: "cross.vial.fill",
                                      label: "薬局 (\(favPharmList.count))",
                                      color: .appPurple)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider().opacity(0.4)

                    // ── コンテンツ ────────────────────────────────
                    if segment == 0 {
                        favMedicineList
                    } else {
                        favPharmacyList
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMed) { med in
                MedicineDetailView(medicine: med)
            }
        }
    }

    // MARK: - ヘッダー
    private var favHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFE8F3"), Color(hex: "F0E8FF")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPink, Color.appPurple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Color.appPink.opacity(0.2), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text("お気に入り")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPink, Color.appPurple],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                let total = favMedList.count + favPharmList.count
                Text(total == 0 ? "まだ登録がありません" : "\(total) 件登録中")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - セグメントボタン
    @ViewBuilder
    private func segmentButton(index: Int, icon: String, label: String, color: Color) -> some View {
        let isSelected = segment == index
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                segment = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? color : (colorScheme == .dark ? Color(hex: "262C39") : Color.white.opacity(0.85)))
            )
            .foregroundColor(isSelected ? .white : .secondary)
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - お気に入り薬リスト
    @ViewBuilder
    private var favMedicineList: some View {
        if favMedList.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "heart.slash")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                Text("お気に入りの薬がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("薬カードのハートボタンから追加できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(favMedList) { med in
                        FriendlyMedicineCard(med: med)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedMed = med }
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 10)
            }
        }
    }

    // MARK: - お気に入り薬局リスト
    @ViewBuilder
    private var favPharmacyList: some View {
        if favPharmList.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "cross.vial")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                Text("お気に入りの薬局がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("薬局カードのハートボタンから追加できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(favPharmList) { ph in
                        PharmacyRow(pharmacy: ph)
                            .padding(.horizontal, 16)
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 10)
            }
        }
    }
}
