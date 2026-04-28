import SwiftUI

enum AppThemeMode: Int, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "自動"
        case .light: return "ライト"
        case .dark: return "ダーク"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var favMedicines: Set<Int> = []
    @Published var favPharmacies: Set<String> = []
    @Published var favoritePharmacyRecords: [String: Pharmacy] = [:]
    @Published var proMode: Bool = false
    @Published var themeMode: AppThemeMode
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""

    private let favoriteMedicinesKey = "favoriteMedicineIDs"
    private let favoritePharmaciesKey = "favoritePharmacyIDs"
    private let favoritePharmacyRecordsKey = "favoritePharmacyRecords"
    private let themeModeKey = "appThemeMode"

    var totalFavCount: Int {
        visibleFavoriteMedicineCount + visibleFavoritePharmacyCount
    }

    private var visibleFavoriteMedicineCount: Int {
        favMedicines.filter { MedicineRepository.shared.medicine(for: $0) != nil }.count
    }

    private var visibleFavoritePharmacyCount: Int {
        favPharmacies.filter { favoritePharmacy(for: $0) != nil }.count
    }

    init() {
        let savedTheme = UserDefaults.standard.integer(forKey: themeModeKey)
        themeMode = AppThemeMode(rawValue: savedTheme) ?? .system
        loadFavorites()
    }

    func toggleMed(_ medicine: Medicine) {
        MedicineRepository.shared.upsert(medicine)
        toggleMed(medicine.id)
    }

    func toggleMed(_ id: Int) {
        if favMedicines.contains(id) { favMedicines.remove(id) } else { favMedicines.insert(id) }
        reconcileFavorites()
        persistFavorites()
    }
    func togglePharm(_ id: String) {
        if favPharmacies.contains(id) {
            favPharmacies.remove(id)
            favoritePharmacyRecords.removeValue(forKey: id)
        } else {
            favPharmacies.insert(id)
            if let pharmacy = mockPharmacies.first(where: { $0.id == id }) {
                favoritePharmacyRecords[id] = pharmacy
            }
        }
        reconcileFavorites()
        persistFavorites()
    }
    func togglePharmacy(_ pharmacy: Pharmacy) {
        if favPharmacies.contains(pharmacy.id) {
            favPharmacies.remove(pharmacy.id)
            favoritePharmacyRecords.removeValue(forKey: pharmacy.id)
        } else {
            favPharmacies.insert(pharmacy.id)
            favoritePharmacyRecords[pharmacy.id] = pharmacy
        }
        reconcileFavorites()
        persistFavorites()
    }
    func saveApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "claudeApiKey")
    }

    func setThemeMode(_ mode: AppThemeMode) {
        themeMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: themeModeKey)
    }

    private func loadFavorites() {
        let defaults = UserDefaults.standard
        favMedicines = Set(defaults.array(forKey: favoriteMedicinesKey) as? [Int] ?? [])
        favPharmacies = Set(defaults.array(forKey: favoritePharmaciesKey) as? [String] ?? [])

        if let data = defaults.data(forKey: favoritePharmacyRecordsKey),
           let records = try? JSONDecoder().decode([String: Pharmacy].self, from: data) {
            favoritePharmacyRecords = records
        }

        reconcileFavorites()
        persistFavorites()
    }

    private func persistFavorites() {
        let defaults = UserDefaults.standard
        defaults.set(Array(favMedicines).sorted(), forKey: favoriteMedicinesKey)
        defaults.set(Array(favPharmacies).sorted(), forKey: favoritePharmaciesKey)
        if let data = try? JSONEncoder().encode(favoritePharmacyRecords) {
            defaults.set(data, forKey: favoritePharmacyRecordsKey)
        }
    }

    private func reconcileFavorites() {
        favMedicines = Set(favMedicines.filter { MedicineRepository.shared.medicine(for: $0) != nil })

        for id in favPharmacies where favoritePharmacyRecords[id] == nil {
            if let pharmacy = mockPharmacies.first(where: { $0.id == id }) {
                favoritePharmacyRecords[id] = pharmacy
            }
        }

        favPharmacies = Set(favPharmacies.filter { favoritePharmacy(for: $0) != nil })
        favoritePharmacyRecords = favoritePharmacyRecords.filter { favPharmacies.contains($0.key) }
    }

    private func favoritePharmacy(for id: String) -> Pharmacy? {
        favoritePharmacyRecords[id] ?? mockPharmacies.first(where: { $0.id == id })
    }
}
