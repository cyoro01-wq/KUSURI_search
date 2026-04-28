import Compression
import Foundation

@MainActor
final class MedicineRepository: ObservableObject {
    static let shared = MedicineRepository()

    @Published private(set) var importedMedicines: [Medicine] = []

    private let defaultsKey = "importedMedicines"
    private let compressedDefaultsKey = "importedMedicinesCompressed"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var allMedicinesCache: [Medicine] = []
    private var searchIndex: [Int: String] = [:]

    private init() {
        loadImportedMedicines()
        rebuildCaches()
    }

    var allMedicines: [Medicine] {
        allMedicinesCache
    }

    func upsert(_ medicine: Medicine) {
        if let index = importedMedicines.firstIndex(where: { $0.id == medicine.id }) {
            importedMedicines[index] = medicine
        } else {
            importedMedicines.append(medicine)
        }
        importedMedicines.sort { lhs, rhs in
            if lhs.brandName == rhs.brandName {
                return lhs.name < rhs.name
            }
            return lhs.brandName < rhs.brandName
        }
        rebuildCaches()
        saveImportedMedicines()
    }

    func medicine(for id: Int) -> Medicine? {
        allMedicines.first { $0.id == id }
    }

    func importedMedicine(for id: Int) -> Medicine? {
        importedMedicines.first { $0.id == id }
    }

    func searchableText(for medicine: Medicine) -> String {
        searchIndex[medicine.id] ?? buildSearchText(for: medicine)
    }

    private func loadImportedMedicines() {
        let defaults = UserDefaults.standard

        if let compressed = defaults.data(forKey: compressedDefaultsKey),
           let data = compressed.decompressed(),
           let decoded = try? decoder.decode([Medicine].self, from: data) {
            importedMedicines = decoded
            return
        }

        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? decoder.decode([Medicine].self, from: data) {
            importedMedicines = decoded
            saveImportedMedicines()
            defaults.removeObject(forKey: defaultsKey)
            return
        }

        importedMedicines = []
    }

    private func saveImportedMedicines() {
        guard let data = try? encoder.encode(importedMedicines) else { return }
        let defaults = UserDefaults.standard
        if let compressed = data.compressed() {
            defaults.set(compressed, forKey: compressedDefaultsKey)
            defaults.removeObject(forKey: defaultsKey)
        } else {
            defaults.set(data, forKey: defaultsKey)
        }
    }

    private func rebuildCaches() {
        let merged = importedMedicines + allMedicinesCatalog
        var seen: Set<Int> = []
        allMedicinesCache = merged.filter { medicine in
            seen.insert(medicine.id).inserted
        }
        searchIndex = Dictionary(uniqueKeysWithValues: allMedicinesCache.map { ($0.id, buildSearchText(for: $0)) })
    }

    private func buildSearchText(for medicine: Medicine) -> String {
        let coreTexts = [
            medicine.name,
            medicine.brandName,
            medicine.genericName,
            medicine.kana,
            medicine.category,
            medicine.dosageForm,
            medicine.general.whatIsIt,
            medicine.general.howToTake,
            medicine.general.interactionWarning,
            medicine.pro.mechanism,
            medicine.pro.actionSummary,
            medicine.pro.dosage
        ]

        let relatedTexts =
            medicine.tags
            + medicine.pro.indications
            + medicine.pro.contraindications
            + medicine.pro.monitoring
            + medicine.general.dailyLife
            + medicine.general.sideEffects.map(\.name)
            + medicine.general.sideEffects.map(\.detail)
            + medicine.general.qa.map(\.q)
            + medicine.general.qa.map(\.a)
            + medicine.pricing.generics.map(\.name)
            + medicine.pricing.generics.map(\.maker)
            + medicine.imprintCodes

        return (coreTexts + relatedTexts)
            .compactMap { $0 }
        .joined(separator: " ")
        .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
        .lowercased()
    }
}

private let allMedicinesCatalog: [Medicine] = allMedicines

private extension Data {
    func compressed() -> Data? {
        withUnsafeBytes { sourceBuffer in
            guard let source = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
            let destinationSize = count + 1024
            let destination = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
            defer { destination.deallocate() }

            let compressedSize = compression_encode_buffer(
                destination,
                destinationSize,
                source,
                count,
                nil,
                COMPRESSION_LZFSE
            )
            guard compressedSize > 0 else { return nil }
            return Data(bytes: destination, count: compressedSize)
        }
    }

    func decompressed() -> Data? {
        withUnsafeBytes { sourceBuffer in
            guard let source = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
            var destinationSize = Swift.max(count * 4, 64 * 1024)

            for _ in 0..<5 {
                let destination = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
                defer { destination.deallocate() }

                let decompressedSize = compression_decode_buffer(
                    destination,
                    destinationSize,
                    source,
                    count,
                    nil,
                    COMPRESSION_LZFSE
                )

                if decompressedSize > 0 {
                    return Data(bytes: destination, count: decompressedSize)
                }
                destinationSize *= 2
            }

            return nil
        }
    }
}
