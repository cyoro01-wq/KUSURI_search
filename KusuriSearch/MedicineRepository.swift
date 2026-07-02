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
    private var medicinesByID: [Int: Medicine] = [:]
    private var searchIndex: [Int: String] = [:]
    private var nameKeys: [Int: [String]] = [:]
    private(set) var availableCategories: [String] = []

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
        medicinesByID[id]
    }

    func importedMedicine(for id: Int) -> Medicine? {
        importedMedicines.first { $0.id == id }
    }

    func searchableText(for medicine: Medicine) -> String {
        searchIndex[medicine.id] ?? buildSearchText(for: medicine)
    }

    static func normalizeForSearch(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .lowercased()
    }

    /// クエリに一致する薬を関連度の高い順に返す。空白区切りの複数キーワードは AND 検索。
    /// 薬品名への一致（完全 > 前方 > 部分）を説明文などへの一致より優先し、
    /// 1文字程度の打ち間違いはあいまい一致で補う。ひらがな・カタカナの違いも吸収する。
    func searchResults(for rawQuery: String) -> (medicines: [Medicine], usedFuzzy: Bool) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (allMedicinesCache, false) }

        let tokens = trimmed
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { Self.normalizeForSearch($0) }
        guard !tokens.isEmpty else { return (allMedicinesCache, false) }

        let tokenVariants = tokens.map(Self.kanaVariants(of:))

        var scored: [(medicine: Medicine, score: Int, fuzzyOnly: Bool)] = []
        for medicine in allMedicinesCache {
            guard let text = searchIndex[medicine.id] else { continue }
            let keys = nameKeys[medicine.id] ?? []

            var total = 0
            var fuzzyOnly = true
            var matchedAll = true

            for (token, variants) in zip(tokens, tokenVariants) {
                let score = Self.tokenScore(variants: variants, nameKeys: keys, fullText: text)
                if score > 0 {
                    total += score
                    fuzzyOnly = false
                    continue
                }
                // 1〜2文字のクエリは誤ヒットが多すぎるため完全一致のみ
                let maxDistance = token.count >= 3 ? 1 : 0
                if maxDistance > 0,
                   keys.contains(where: { key in
                       variants.contains { Self.approximatelyContains(key, query: $0, maxDistance: maxDistance) }
                   }) {
                    total += 5
                } else {
                    matchedAll = false
                    break
                }
            }

            if matchedAll {
                scored.append((medicine, total, fuzzyOnly))
            }
        }

        scored.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.medicine.brandName < rhs.medicine.brandName
        }
        let usedFuzzy = !scored.isEmpty && scored.allSatisfy { $0.fuzzyOnly }
        return (scored.map(\.medicine), usedFuzzy)
    }

    /// ひらがな・カタカナ両表記のゆらぎを吸収した検索キーの一覧を返す
    private static func kanaVariants(of normalized: String) -> [String] {
        var variants: [String] = [normalized]
        if let katakana = normalized.applyingTransform(.hiraganaToKatakana, reverse: false),
           katakana != normalized {
            variants.append(katakana)
        }
        if let hiragana = normalized.applyingTransform(.hiraganaToKatakana, reverse: true),
           hiragana != normalized, !variants.contains(hiragana) {
            variants.append(hiragana)
        }
        return variants
    }

    /// 薬品名への一致（完全 > 前方 > 部分）を本文一致より高く採点する
    private static func tokenScore(variants: [String], nameKeys: [String], fullText: String) -> Int {
        var best = 0
        for variant in variants {
            for key in nameKeys {
                if key == variant {
                    best = max(best, 100)
                } else if key.hasPrefix(variant) {
                    best = max(best, 80)
                } else if key.contains(variant) {
                    best = max(best, 60)
                }
            }
            if best < 60, fullText.contains(variant) {
                best = max(best, 30)
            }
        }
        return best
    }

    /// text のどこかに、query と編集距離 maxDistance 以内の部分文字列があるか（Sellers法）
    private static func approximatelyContains(_ text: String, query: String, maxDistance: Int) -> Bool {
        let q = Array(query)
        let t = Array(text)
        let m = q.count
        guard m > 0, !t.isEmpty, t.count + maxDistance >= m else { return false }

        var previous = Array(0...m)
        var current = [Int](repeating: 0, count: m + 1)
        for j in 1...t.count {
            current[0] = 0
            for i in 1...m {
                let substitutionCost = q[i - 1] == t[j - 1] ? 0 : 1
                current[i] = Swift.min(
                    previous[i] + 1,
                    current[i - 1] + 1,
                    previous[i - 1] + substitutionCost
                )
            }
            if current[m] <= maxDistance { return true }
            swap(&previous, &current)
        }
        return false
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
        medicinesByID = Dictionary(uniqueKeysWithValues: allMedicinesCache.map { ($0.id, $0) })
        searchIndex = Dictionary(uniqueKeysWithValues: allMedicinesCache.map { ($0.id, buildSearchText(for: $0)) })
        nameKeys = Dictionary(uniqueKeysWithValues: allMedicinesCache.map { medicine in
            let keys = ([medicine.brandName, medicine.name, medicine.genericName, medicine.kana] + medicine.tags)
                .filter { !$0.isEmpty }
                .map { Self.normalizeForSearch($0) }
            return (medicine.id, keys)
        })
        availableCategories = Array(
            Set(
                allMedicinesCache
                    .map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
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
            + medicine.webTopics
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
