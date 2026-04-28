import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var medicineRepository = MedicineRepository.shared
    @State private var segment = 0
    @State private var selectedMed: Medicine? = nil

    var favMedList:  [Medicine]  { medicineRepository.allMedicines.filter  { appState.favMedicines.contains($0.id)  } }
    var favPharmList: [Pharmacy] {
        appState.favoritePharmacyRecords
            .filter { appState.favPharmacies.contains($0.key) }
            .map(\.value)
            .sorted { lhs, rhs in
            let lhsDistance = lhs.distance ?? 9999
            let rhsDistance = rhs.distance ?? 9999
            if lhsDistance == rhsDistance {
                return lhs.name < rhs.name
            }
            return lhsDistance < rhsDistance
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("💊 薬 (\(favMedList.count))").tag(0)
                    Text("🏥 薬局 (\(favPharmList.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                if segment == 0 {
                    if favMedList.isEmpty {
                        ContentUnavailableView(
                            "お気に入りの薬がありません",
                            systemImage: "pills",
                            description: Text("薬カードのハートボタンから追加できます")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(favMedList) { med in
                                    MedicineRow(med: med)
                                        .padding(.horizontal)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedMed = med }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                } else {
                    if favPharmList.isEmpty {
                        ContentUnavailableView(
                            "お気に入りの薬局がありません",
                            systemImage: "cross.vial",
                            description: Text("薬局カードのハートボタンから追加できます")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(favPharmList) { ph in
                                    PharmacyRow(pharmacy: ph)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("❤️ お気に入り")
            .sheet(item: $selectedMed) { med in
                MedicineDetailView(medicine: med)
            }
        }
    }
}
