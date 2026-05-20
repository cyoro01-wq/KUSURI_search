import Foundation
import PDFKit

enum PMDAServiceError: LocalizedError {
    case searchFailed
    case detailNotFound

    var errorDescription: String? {
        switch self {
        case .searchFailed:
            return "公開医薬品データベースで薬品名を検索できませんでした。"
        case .detailNotFound:
            return "薬品の詳細情報ページを特定できませんでした。"
        }
    }
}

struct PMDAFetchedDrug {
    let brandName: String
    let genericName: String
    let manufacturer: String
    let manufacturerDetail: String
    let detailURL: URL
    let htmlURL: URL
    let packageInsertURL: URL?
    let indications: String
    let dosage: String
    let dosagePrecautions: String
    let mechanism: String
    let contraindications: String
    let interactionPrecautions: String
    let importantPrecautions: String
    let packageInfo: String
    let drugClass: String
    let priceText: String
    let genericProducts: [Medicine.Pricing.PriceItem]
    let adverseEffects: [Medicine.AdverseEffect]
    let patientSideEffects: [Medicine.SideEffect]
    let documentSections: [Medicine.ProInfo.DocumentSection]
    let photoURL: URL?
    let rx: Bool
}

private struct KEGGSearchEntry {
    let display: String
    let brandName: String
    let genericName: String
    let manufacturer: String
    let drugClass: String
    let detailURL: URL
    let rx: Bool
}

private struct RADARSearchResponse: Decodable {
    let items: [RADARSearchItem]
}

private struct RADARSearchItem: Decodable {
    struct SideEffect: Decodable {
        let common: String?
    }

    struct Company: Decodable {
        let name: String
        let url: String
    }

    let id: String
    let name: String
    let photo: String?
    let preparation: String?
    let dosage_form: String?
    let print: String?
    let effect: String?
    let attachment: String?
    let message: [String]?
    let dosing: [String]?
    let precautions: [String]?
    let comment: [String]?
    let active_ingredient: [String]?
    let side_effect: SideEffect?
    let company: Company?
}

actor PMDACache {
    private var drugsByQuery: [String: PMDAFetchedDrug] = [:]

    func value(for query: String) -> PMDAFetchedDrug? {
        drugsByQuery[query]
    }

    func set(_ drug: PMDAFetchedDrug, for query: String) {
        drugsByQuery[query] = drug
    }
}

actor RADARPhotoCache {
    private var photoURLByQuery: [String: URL?] = [:]

    func value(for query: String) -> URL?? {
        if photoURLByQuery.keys.contains(query) {
            return photoURLByQuery[query]
        }
        return nil
    }

    func set(_ url: URL?, for query: String) {
        photoURLByQuery[query] = url
    }
}

enum PMDAService {
    private static let baseURL = URL(string: "https://www.kegg.jp")!
    private static let radArBaseURL = URL(string: "https://www.rad-ar.or.jp")!
    private static let cache = PMDACache()
    private static let photoCache = RADARPhotoCache()

    static func enrich(_ medicine: Medicine) async throws -> Medicine {
        let fetched = try await fetchDrug(named: medicine.brandName, fallbackName: medicine.genericName)
        let radarItem = await fetchRADARItem(
            primaryName: fetched.brandName.isEmpty ? medicine.brandName : fetched.brandName,
            fallbackName: fetched.genericName.isEmpty ? medicine.genericName : fetched.genericName
        )
        let photoURL = radarItem.flatMap(photoURL(from:)) ?? fetched.photoURL ?? medicine.photoURL
        let descriptionLabel = displayCategoryLabel(medicine.category, fallback: fetched.drugClass)
        let actionSummary = [
            medicine.pro.actionSummary,
            fetched.drugClass.isEmpty ? nil : "薬効分類: \(fetched.drugClass)"
        ]
        .compactMap { normalizedText($0) }
        .joined(separator: "\n")

        let mergedPro = Medicine.ProInfo(
            mechanism: fetched.mechanism.isEmpty ? medicine.pro.mechanism : fetched.mechanism,
            actionSummary: actionSummary,
            indications: fetched.indications.isEmpty ? medicine.pro.indications : splitParagraphs(fetched.indications),
            dosage: fetched.dosage.isEmpty ? medicine.pro.dosage : fetched.dosage,
            dosageNotes: fetched.dosagePrecautions.isEmpty ? medicine.pro.dosageNotes : splitParagraphs(fetched.dosagePrecautions),
            contraindications: fetched.contraindications.isEmpty ? medicine.pro.contraindications : splitParagraphs(fetched.contraindications),
            adverseEffects: fetched.adverseEffects.isEmpty ? medicine.pro.adverseEffects : fetched.adverseEffects,
            pk: medicine.pro.pk,
            monitoring: fetched.importantPrecautions.isEmpty ? medicine.pro.monitoring : splitParagraphs(fetched.importantPrecautions),
            pregnancyCategory: medicine.pro.pregnancyCategory,
            documentSections: fetched.documentSections.isEmpty ? medicine.pro.documentSections : fetched.documentSections
        )

        let patientSummary = [
            fetched.brandName.isEmpty ? nil : "\(fetched.brandName)は\(descriptionLabel)として使われるお薬です。",
            fetched.drugClass.isEmpty ? nil : "分類は\(fetched.drugClass)です。",
            fetched.indications.isEmpty ? nil : "主な使いみちは\(fetched.indications)。",
            medicine.general.whatIsIt
        ]
        .compactMap { normalizedText($0) }
        .joined(separator: " ")

        let mergedGeneral = Medicine.GeneralInfo(
            whatIsIt: patientSummary.isEmpty ? medicine.general.whatIsIt : patientSummary,
            howToTake: fetched.dosage.isEmpty ? medicine.general.howToTake : fetched.dosage,
            sideEffects: fetched.patientSideEffects.isEmpty ? medicine.general.sideEffects : fetched.patientSideEffects,
            dailyLife: medicine.general.dailyLife,
            interactionWarning: fetched.interactionPrecautions.isEmpty ? medicine.general.interactionWarning : fetched.interactionPrecautions,
            qa: medicine.general.qa
        )

        let mergedPricing = mergedPricing(base: medicine.pricing, fetched: fetched)
        let mergedTags = fetched.packageInsertURL == nil || medicine.tags.contains("添付文書PDF")
            ? medicine.tags
            : medicine.tags + ["添付文書PDF"]

        return Medicine(
            id: medicine.id,
            name: medicine.name,
            kana: medicine.kana,
            genericName: fetched.genericName.isEmpty ? medicine.genericName : fetched.genericName,
            brandName: fetched.brandName.isEmpty ? medicine.brandName : fetched.brandName,
            category: medicine.category,
            maker: fetched.manufacturer.isEmpty ? medicine.maker : fetched.manufacturer,
            makerURLString: fetched.manufacturer.isEmpty
                ? fetched.detailURL.absoluteString
                : Medicine.manufacturerURL(for: fetched.manufacturer),
            packageInsertURLString: fetched.packageInsertURL?.absoluteString,
            photoURLString: photoURL?.absoluteString ?? medicine.photoURLString,
            dosageForm: cleanedDosageForm(from: radarItem) ?? medicine.dosageForm,
            imprintCodes: mergedImprintCodes(primary: medicine.imprintCodes, fallback: imprintCodes(from: radarItem)),
            tags: mergedTags,
            rx: fetched.rx,
            pricing: mergedPricing,
            interactions: medicine.interactions,
            pro: mergedPro,
            general: mergedGeneral
        )
    }

    static func fetchTemporaryMedicine(named name: String) async throws -> Medicine {
        let fetched: PMDAFetchedDrug
        do {
            fetched = try await fetchDrug(named: name, fallbackName: nil)
        } catch {
            if let radarItem = await fetchRADARItem(primaryName: name, fallbackName: nil),
               normalizedSearchText(radarItem.name) != normalizedSearchText(name) {
                if let resolved = try? await fetchTemporaryMedicine(named: radarItem.name) {
                    return resolved
                }
                return temporaryMedicine(from: radarItem, query: name)
            }
            if let radarItem = await fetchRADARItem(primaryName: name, fallbackName: nil) {
                return temporaryMedicine(from: radarItem, query: name)
            }
            throw error
        }

        let radarItem = await fetchRADARItem(
            primaryName: fetched.brandName.isEmpty ? name : fetched.brandName,
            fallbackName: fetched.genericName.isEmpty ? nil : fetched.genericName
        )
        let photoURL = radarItem.flatMap(photoURL(from:)) ?? fetched.photoURL
        let displayName = fetched.genericName.isEmpty ? name : fetched.genericName
        let displayBrand = fetched.brandName.isEmpty ? name : fetched.brandName
        let manufacturer = fetched.manufacturer.isEmpty ? "製造販売業者情報未取得" : fetched.manufacturer
        let category = fetched.drugClass.isEmpty ? (fetched.rx ? "医療用医薬品" : "一般用医薬品") : fetched.drugClass
        let patientWhatIsIt = [
            "\(displayBrand)は\(category)です。",
            fetched.indications.isEmpty ? nil : "主な使いみちは\(fetched.indications)です。",
            fetched.packageInfo.isEmpty ? nil : "包装や規格は\(fetched.packageInfo)です。"
        ]
        .compactMap { normalizedText($0) }
        .joined(separator: " ")
        let actionSummary = [
            fetched.drugClass.isEmpty ? nil : "薬効分類: \(fetched.drugClass)"
        ]
        .compactMap { normalizedText($0) }
        .joined(separator: "\n")

        let sourceTags = fetched.packageInsertURL == nil
            ? ["医薬品DB", "添付文書", "自動取得"]
            : ["医薬品DB", "添付文書PDF", "自動取得"]

        let medicine = Medicine(
            id: importedMedicineID(brandName: displayBrand, genericName: displayName, maker: manufacturer),
            name: displayName,
            kana: name,
            genericName: displayName,
            brandName: displayBrand,
            category: category,
            maker: manufacturer,
            makerURLString: fetched.manufacturer.isEmpty
                ? fetched.detailURL.absoluteString
                : Medicine.manufacturerURL(for: manufacturer),
            packageInsertURLString: fetched.packageInsertURL?.absoluteString,
            photoURLString: photoURL?.absoluteString,
            dosageForm: cleanedDosageForm(from: radarItem),
            imprintCodes: imprintCodes(from: radarItem),
            tags: sourceTags,
            rx: fetched.rx,
            pricing: pricing(for: fetched, brandName: displayBrand, maker: manufacturer),
            interactions: [],
            pro: Medicine.ProInfo(
                mechanism: fetched.mechanism.isEmpty ? category : fetched.mechanism,
                actionSummary: actionSummary,
                indications: splitParagraphs(fetched.indications),
                dosage: fetched.dosage,
                dosageNotes: splitParagraphs(fetched.dosagePrecautions),
                contraindications: splitParagraphs(fetched.contraindications),
                adverseEffects: fetched.adverseEffects,
                pk: .init(
                    tmax: "公開情報から自動取得できませんでした",
                    halfLife: "公開情報から自動取得できませんでした",
                    proteinBinding: "公開情報から自動取得できませんでした",
                    metabolism: "公開情報から自動取得できませんでした",
                    excretion: "公開情報から自動取得できませんでした"
                ),
                monitoring: splitParagraphs(fetched.importantPrecautions),
                pregnancyCategory: "原資料をご確認ください",
                documentSections: fetched.documentSections
            ),
            general: Medicine.GeneralInfo(
                whatIsIt: patientWhatIsIt,
                howToTake: fetched.dosage,
                sideEffects: fetched.patientSideEffects,
                dailyLife: [
                    "添付文書やメーカー公開情報とあわせて確認してください",
                    "症状や副作用の変化があれば医師・薬剤師に相談してください"
                ] + (fetched.packageInfo.isEmpty ? [] : ["包装・規格: \(fetched.packageInfo)"]),
                interactionWarning: fetched.interactionPrecautions.isEmpty ? "併用薬、市販薬、サプリメント、飲酒習慣がある場合は事前に医師・薬剤師へ伝えてください。" : fetched.interactionPrecautions,
                qa: [
                    .init(q: "さらに詳しい資料は？", a: "添付文書原文やメーカー公式情報もあわせて確認してください。"),
                    .init(q: "表示内容は最新ですか？", a: "公開データベースをもとに整形していますが、改訂時は原資料の確認が必要です。")
                ]
            )
        )

        await MainActor.run {
            MedicineRepository.shared.upsert(medicine)
        }
        return medicine
    }

    private static func temporaryMedicine(from radarItem: RADARSearchItem, query: String) -> Medicine {
        let brandName = normalizedText(radarItem.name) ?? query
        let genericName = normalizedText(radarItem.active_ingredient?.joined(separator: "、")) ?? brandName
        let manufacturer = normalizedText(radarItem.company?.name) ?? "製造販売業者情報未取得"
        let dosage = summarizeClinicalText((radarItem.dosing ?? []).joined(separator: "\n"), maxItems: 6, separator: "\n")
        let effect = normalizedText(htmlText(from: radarItem.effect ?? "")) ?? ""
        let precautions = summarizeClinicalText((radarItem.message ?? []).joined(separator: "\n"), maxItems: 5, separator: "\n")
        let interactionWarning = summarizeInteractionWarnings(from: (radarItem.message ?? []).joined(separator: "\n"))
        let sideEffects = patientSideEffectsFromRADAR(radarItem)
        let dosageForm = cleanedDosageForm(from: radarItem)
        let imprintList = imprintCodes(from: radarItem)

        let medicine = Medicine(
            id: importedMedicineID(brandName: brandName, genericName: genericName, maker: manufacturer),
            name: genericName,
            kana: query,
            genericName: genericName,
            brandName: brandName,
            category: dosageForm ?? "医薬品",
            maker: manufacturer,
            makerURLString: radarItem.company?.url ?? Medicine.manufacturerURL(for: manufacturer),
            packageInsertURLString: absoluteRADARURL(for: radarItem.attachment ?? "")?.absoluteString,
            photoURLString: photoURL(from: radarItem)?.absoluteString,
            dosageForm: dosageForm,
            imprintCodes: imprintList,
            tags: ["医薬品DB", "自動取得"],
            rx: true,
            pricing: .init(
                brand: .init(name: brandName, price: 0, maker: manufacturer),
                generics: [],
                unit: dosageForm?.contains("カプセル") == true ? "カプセル" : "錠",
                source: "くすりのしおり",
                patientBurden30: "薬価未取得"
            ),
            interactions: [],
            pro: .init(
                mechanism: effect.isEmpty ? "公開情報から自動取得した概要です。" : effect,
                actionSummary: dosageForm ?? "",
                indications: splitParagraphs(effect),
                dosage: dosage.isEmpty ? "用法・用量は添付文書と医師・薬剤師の指示を確認してください。" : dosage,
                contraindications: splitParagraphs(precautions),
                adverseEffects: [],
                pk: .init(
                    tmax: "公開情報から自動取得できませんでした",
                    halfLife: "公開情報から自動取得できませんでした",
                    proteinBinding: "公開情報から自動取得できませんでした",
                    metabolism: "公開情報から自動取得できませんでした",
                    excretion: "公開情報から自動取得できませんでした"
                ),
                monitoring: splitParagraphs(precautions),
                pregnancyCategory: "原資料をご確認ください",
                documentSections: []
            ),
            general: .init(
                whatIsIt: effect.isEmpty ? "\(brandName)の公開情報を自動取得しました。" : effect,
                howToTake: dosage.isEmpty ? "使い方は添付文書と指示を確認してください。" : dosage,
                sideEffects: sideEffects,
                dailyLife: splitParagraphs((radarItem.comment ?? []).joined(separator: "\n")),
                interactionWarning: interactionWarning.isEmpty ? "併用薬、市販薬、サプリメントがあれば事前に医師・薬剤師へ伝えてください。" : interactionWarning,
                qa: [
                    .init(q: "識別コードで探せますか？", a: imprintList.isEmpty ? "識別コード情報は未取得です。" : imprintList.joined(separator: " / "))
                ]
            )
        )

        Task { @MainActor in
            MedicineRepository.shared.upsert(medicine)
        }

        return medicine
    }

    private static func fetchDrug(named name: String, fallbackName: String?) async throws -> PMDAFetchedDrug {
        let primaryQuery = normalizedQuery(name)
        if let cached = await cache.value(for: primaryQuery) {
            return cached
        }

        if let fetched = try await fetchDrugForSingleQuery(primaryQuery) {
            await cache.set(fetched, for: primaryQuery)
            return fetched
        }

        if let fallbackName {
            let fallbackQuery = normalizedQuery(fallbackName)
            if let cached = await cache.value(for: fallbackQuery) {
                return cached
            }
            if let fetched = try await fetchDrugForSingleQuery(fallbackQuery) {
                await cache.set(fetched, for: primaryQuery)
                await cache.set(fetched, for: fallbackQuery)
                return fetched
            }
        }

        for alias in aliasQueries(for: primaryQuery) {
            if let cached = await cache.value(for: alias) {
                await cache.set(cached, for: primaryQuery)
                return cached
            }
            if let fetched = try await fetchDrugForSingleQuery(alias) {
                await cache.set(fetched, for: primaryQuery)
                await cache.set(fetched, for: alias)
                return fetched
            }
        }

        throw PMDAServiceError.detailNotFound
    }

    private static func fetchDrugForSingleQuery(_ query: String) async throws -> PMDAFetchedDrug? {
        guard let entry = try await resolveSearchEntry(for: query) else {
            return nil
        }
        return try await fetchDrug(entry: entry)
    }

    private static func resolveSearchEntry(for query: String) async throws -> KEGGSearchEntry? {
        let trimmedQuery = normalizedQuery(query)
        guard !trimmedQuery.isEmpty else { return nil }

        let entries = try await fetchEntries(for: trimmedQuery, displays: ["med", "otc"])
        return entries.max(by: { score($0, for: trimmedQuery) < score($1, for: trimmedQuery) })
    }

    private static func fetchEntries(for query: String, displays: [String]) async throws -> [KEGGSearchEntry] {
        var entries: [KEGGSearchEntry] = []
        for display in displays {
            var components = URLComponents(url: baseURL.appendingPathComponent("/medicus-bin/search_drug"), resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "search_keyword", value: query),
                URLQueryItem(name: "display", value: display)
            ]
            guard let url = components?.url else {
                throw PMDAServiceError.searchFailed
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(decoding: data, as: UTF8.self)
            entries += parseSearchEntries(from: html, display: display)
        }
        return entries
    }

    private static func parseSearchEntries(from html: String, display: String) -> [KEGGSearchEntry] {
        let pattern: String
        if display == "med" {
            pattern = #"(?s)<td class="data1">\s*<a href="japic_med\?japic_code=([^"]+)">\s*(.*?)\s*</a>\s*<br>\((.*?)\)\s*</td>\s*<td class="data1 mw50pc">(.*?)</td>\s*<td class="data1">(.*?)</td>"#
        } else {
            pattern = #"(?s)<td class="data1"><a href="japic_otc\?japic_code=([^"]+)">(.*?)</a></td>\s*<td class="data1">(.*?)</td>\s*<td class="data1">(.*?)</td>\s*<td class="data1">(.*?)</td>"#
        }

        return html.captureGroups(pattern).compactMap { groups in
            guard groups.count >= 5 else { return nil }
            let code = groups[0]
            let brandName = htmlText(from: groups[1])
            let manufacturer = htmlText(from: groups[2])
            let genericName = display == "med" ? htmlText(from: groups[3]) : ""
            let drugClass = htmlText(from: groups[display == "med" ? 4 : 3])
            let path = display == "med"
                ? "/medicus-bin/japic_med?japic_code=\(code)"
                : "/medicus-bin/japic_otc?japic_code=\(code)"
            guard let detailURL = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
                return nil
            }
            return KEGGSearchEntry(
                display: display,
                brandName: brandName,
                genericName: genericName,
                manufacturer: manufacturer,
                drugClass: drugClass,
                detailURL: detailURL,
                rx: display == "med"
            )
        }
    }

    private static func fetchDrug(entry: KEGGSearchEntry) async throws -> PMDAFetchedDrug {
        let (detailData, _) = try await URLSession.shared.data(from: entry.detailURL)
        let detailHTML = String(decoding: detailData, as: UTF8.self)

        if entry.display == "otc" {
            return await fetchOTCDrug(entry: entry, detailHTML: detailHTML)
        }

        let manufacturerDetail = extractSection(detailHTML, id: "par-26", next: "script type=\"text/javascript\"")
        let manufacturer = firstMeaningfulLine(in: manufacturerDetail) ?? entry.manufacturer
        let brandName = captureTableValue(detailHTML, header: "総称名") ?? entry.brandName
        let genericName = captureTableValue(detailHTML, header: "一般名") ?? entry.genericName
        let drugClass = captureTableValue(detailHTML, header: "薬効分類名") ?? entry.drugClass
        let mechanismSection = extractSection(detailHTML, id: "par-18", next: "par-19")
        let rawMechanism = sanitizeClinicalSection(
            extractSubsection(detailHTML, id: "par-18_1").ifEmpty(mechanismSection)
        )
        let adverseSection = summarizeClinicalText(
            sanitizeClinicalSection(extractSection(detailHTML, id: "par-11", next: "par-14")),
            maxItems: 8,
            separator: "\n"
        )
        let adverseEffects = extractAdverseEffects(from: detailHTML, fallbackText: adverseSection)
        let priceText = extractPriceText(from: detailHTML)
        let genericProducts = await fetchGenericProducts(
            from: extractSimilarProductURL(from: detailHTML, relativeTo: entry.detailURL),
            genericName: genericName,
            brandName: brandName
        )
        let packageInsertURL = extractPackageInsertURL(from: detailHTML, relativeTo: entry.detailURL)
        let packageInsertText = await fetchPackageInsertText(from: packageInsertURL)
        let indications = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["4"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-4", next: "par-6")),
            maxItems: 8,
            separator: "\n"
        )
        let dosage = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["6"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-6", next: "par-7")),
            maxItems: 5
        )
        let dosagePrecautions = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["7"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-7", next: "par-8")),
            maxItems: 6,
            separator: "\n"
        )
        let contraindications = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["2"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-2", next: "par-4")),
            maxItems: 8,
            separator: "\n"
        )
        let interactionPrecautions = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["10"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-10", next: "par-11")),
            maxItems: 6,
            separator: "\n",
            contentFilter: isInteractionWarningLine(_:)
        )
        let importantPrecautions = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["8"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-8", next: "par-9")),
            maxItems: 8,
            separator: "\n"
        )
        let packageInfo = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["22"],
            fallback: sanitizeClinicalSection(extractSection(detailHTML, id: "par-22", next: "par-23")),
            maxItems: 4
        )
        let documentSections = extractStructuredPackageSections(from: packageInsertText)
        let mechanism = preferredPackageSection(
            pdfText: packageInsertText,
            headingNumbers: ["18", "18.1"],
            fallback: rawMechanism,
            maxItems: 4,
            contentFilter: isMechanismLine(_:)
        )
        let pdfAdverseSection = packageInsertText.flatMap {
            extractPackageInsertSection(from: $0, headingNumbers: ["11"])
        }
        let adverseEffectsFromPDF = pdfAdverseSection.map(fallbackAdverseEffects(from:)) ?? []
        let tableEffects = tableAdverseEffects(from: detailHTML)
        let mergedAdverseEffects = mergeAdverseEffects(
            primary: tableEffects + adverseEffects,
            secondary: adverseEffectsFromPDF
        )

        return PMDAFetchedDrug(
            brandName: brandName,
            genericName: genericName,
            manufacturer: manufacturer,
            manufacturerDetail: manufacturerDetail,
            detailURL: entry.detailURL,
            htmlURL: entry.detailURL,
            packageInsertURL: packageInsertURL,
            indications: indications,
            dosage: dosage,
            dosagePrecautions: dosagePrecautions,
            mechanism: mechanism,
            contraindications: contraindications,
            interactionPrecautions: interactionPrecautions,
            importantPrecautions: importantPrecautions,
            packageInfo: packageInfo,
            drugClass: drugClass,
            priceText: priceText,
            genericProducts: genericProducts,
            adverseEffects: mergedAdverseEffects,
            patientSideEffects: patientSideEffects(from: mergedAdverseEffects),
            documentSections: documentSections,
            photoURL: await fetchPhotoURL(primaryName: brandName, fallbackName: genericName),
            rx: true
        )
    }

    private static func fetchOTCDrug(entry: KEGGSearchEntry, detailHTML: String) async -> PMDAFetchedDrug {
        let brandName = captureOTCValue(detailHTML, title: "製品名") ?? entry.brandName
        let manufacturer = captureOTCValue(detailHTML, title: "製造販売元") ?? entry.manufacturer
        let drugClass = captureOTCValue(detailHTML, title: "小分類") ?? entry.drugClass
        let genericName = extractOTCIngredients(detailHTML)
        let packageInfo = captureOTCValue(detailHTML, title: "包装") ?? ""
        let indications = summarizeClinicalText(extractOTCSection(detailHTML, header: "効果・効能"), maxItems: 8, separator: "\n")
        let features = summarizeClinicalText(extractOTCSection(detailHTML, header: "特徴"), maxItems: 4)
        let precautions = summarizeClinicalText(extractOTCSection(detailHTML, header: "使用上の注意"), maxItems: 10, separator: "\n")
        let sideEffects = otcSideEffects(from: precautions)

        return PMDAFetchedDrug(
            brandName: brandName,
            genericName: genericName,
            manufacturer: manufacturer,
            manufacturerDetail: manufacturer,
            detailURL: entry.detailURL,
            htmlURL: entry.detailURL,
            packageInsertURL: extractPackageInsertURL(from: detailHTML, relativeTo: entry.detailURL),
            indications: indications,
            dosage: "一般用医薬品のため、用法・用量は製品パッケージと添付文書の記載に従ってください。",
            dosagePrecautions: summarizeClinicalText(precautions, maxItems: 6, separator: "\n"),
            mechanism: features,
            contraindications: summarizeClinicalText(precautions, maxItems: 8, separator: "\n"),
            interactionPrecautions: summarizeInteractionWarnings(from: precautions),
            importantPrecautions: precautions,
            packageInfo: packageInfo,
            drugClass: drugClass,
            priceText: "",
            genericProducts: [],
            adverseEffects: sideEffects,
            patientSideEffects: patientSideEffects(from: sideEffects),
            documentSections: [],
            photoURL: await fetchPhotoURL(primaryName: brandName, fallbackName: genericName),
            rx: false
        )
    }

    private static func fetchPhotoURL(primaryName: String, fallbackName: String?) async -> URL? {
        let item = await fetchRADARItem(primaryName: primaryName, fallbackName: fallbackName)
        return item.flatMap(photoURL(from:))
    }

    private static func fetchPhotoURLForSingleQuery(_ query: String) async -> URL? {
        let item = await fetchRADARItemForSingleQuery(query)
        await photoCache.set(item.flatMap(photoURL(from:)), for: query)
        return item.flatMap(photoURL(from:))
    }

    private static func fetchRADARItem(primaryName: String, fallbackName: String?) async -> RADARSearchItem? {
        let queries = [primaryName, fallbackName]
            .compactMap { $0 }
            .map(normalizedQuery)
            .filter { !$0.isEmpty }

        for query in queries {
            if let item = await fetchRADARItemForSingleQuery(query) {
                return item
            }
        }

        return nil
    }

    private static func fetchRADARItemForSingleQuery(_ query: String) async -> RADARSearchItem? {
        for searchKey in radarSearchKeys(for: query) {
            var components = URLComponents(url: radArBaseURL.appendingPathComponent("/siori_register/siori_api/"), resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "w", value: query),
                URLQueryItem(name: "r", value: "k"),
                URLQueryItem(name: "k", value: searchKey),
                URLQueryItem(name: "v", value: "25"),
                URLQueryItem(name: "p", value: "1"),
                URLQueryItem(name: "g", value: "0")
            ]

            guard let url = components?.url else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(RADARSearchResponse.self, from: data)
                guard let bestMatch = response.items.max(by: { radarScore($0, for: query) < radarScore($1, for: query) }),
                      radarScore(bestMatch, for: query) > 0 else {
                    continue
                }
                return bestMatch
            } catch {
                continue
            }
        }

        return nil
    }

    private static func radarScore(_ item: RADARSearchItem, for query: String) -> Int {
        let normalizedItemName = normalizedSearchText(item.name)
        let normalizedQuery = normalizedSearchText(query)
        let normalizedPrint = normalizedSearchText(item.print ?? "")
        let dosageForm = normalizedSearchText(item.dosage_form ?? "")
        let preparation = normalizedSearchText(item.preparation ?? "")

        var score = 0
        if normalizedItemName == normalizedQuery { score += 120 }
        else if normalizedItemName.hasPrefix(normalizedQuery) { score += 90 }
        else if normalizedItemName.contains(normalizedQuery) { score += 70 }
        else if normalizedQuery.contains(normalizedItemName) { score += 50 }

        if !normalizedPrint.isEmpty {
            if normalizedPrint == normalizedQuery { score += 110 }
            else if normalizedPrint.contains(normalizedQuery) { score += 85 }
            else if normalizedQuery.contains(normalizedPrint) { score += 55 }
        }

        if preparation.contains("内服剤") { score += 10 }
        if dosageForm.contains("錠") { score += 28 }
        if dosageForm.contains("カプセル") { score += 26 }
        if dosageForm.contains("OD") || dosageForm.contains("口腔内崩壊") { score += 10 }
        if dosageForm.contains("散") || dosageForm.contains("細粒") || dosageForm.contains("顆粒") || dosageForm.contains("粉") {
            score -= 24
        }
        if dosageForm.contains("シロップ") || dosageForm.contains("ドライシロップ") {
            score -= 22
        }
        if dosageForm.contains("貼付") || dosageForm.contains("ゲル") || dosageForm.contains("軟膏") || dosageForm.contains("点眼") {
            score -= 26
        }

        return score
    }

    private static func photoURL(from item: RADARSearchItem) -> URL? {
        guard let photoPath = item.photo, !photoPath.isEmpty else { return nil }
        return absoluteRADARURL(for: photoPath)
    }

    private static func radarSearchKeys(for query: String) -> [String] {
        isImprintLikeQuery(query) ? ["p", "t"] : ["t", "p"]
    }

    private static func isImprintLikeQuery(_ query: String) -> Bool {
        let normalized = normalizedSearchText(query)
        guard !normalized.isEmpty else { return false }
        if normalized.range(of: #"^[A-Z]{1,5}\d{1,4}[A-Z]?$"#, options: .regularExpression) != nil { return true }
        if normalized.range(of: #"^[A-Z0-9-]{3,}$"#, options: .regularExpression) != nil { return true }
        if normalized.range(of: #"^\d{3,}$"#, options: .regularExpression) != nil { return true }
        return false
    }

    private static func cleanedDosageForm(from item: RADARSearchItem?) -> String? {
        guard let raw = item?.dosage_form else { return nil }
        return normalizedText(htmlText(from: raw))
    }

    private static func patientSideEffectsFromRADAR(_ item: RADARSearchItem) -> [Medicine.SideEffect] {
        let common = normalizedText(htmlText(from: item.side_effect?.common ?? "")) ?? ""
        let candidates = splitParagraphs(common)
        let names = candidates.flatMap { sentence in
            sentence
                .components(separatedBy: CharacterSet(charactersIn: "、，,。"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        .filter { $0.count >= 2 && !$0.contains("主な副作用として") && !$0.contains("報告されています") }

        var results: [Medicine.SideEffect] = []
        var seen: Set<String> = []

        for name in names.prefix(6) {
            guard seen.insert(name).inserted else { continue }
            results.append(.init(icon: "💊", name: name, detail: common.isEmpty ? "気になる症状があれば医師・薬剤師に相談してください。" : common))
        }

        return results
    }

    private static func mergedImprintCodes(primary: [String], fallback: [String]) -> [String] {
        var seen: Set<String> = []
        return (primary + fallback).filter { value in
            let normalized = normalizedSearchText(value)
            guard !normalized.isEmpty, !seen.contains(normalized) else { return false }
            seen.insert(normalized)
            return true
        }
    }

    private static func imprintCodes(from item: RADARSearchItem?) -> [String] {
        guard let print = item?.print else { return [] }
        let normalizedPrint = normalizedText(htmlText(from: print)) ?? ""
        guard !normalizedPrint.isEmpty else { return [] }

        let separators = CharacterSet(charactersIn: "、,，/／\n")
        let parts = normalizedPrint
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let excludedTerms = [
            "錠", "カプセル", "内服薬", "外用薬", "注射剤", "点眼剤", "経皮吸収型鎮痛", "抗炎症剤",
            "白色", "淡黄色", "淡褐色", "円形", "楕円形", "直径", "長径", "短径"
        ]

        var candidates: [String] = []
        for part in parts {
            let compact = part.replacingOccurrences(of: " ", with: "")
            if excludedTerms.contains(where: { compact.contains($0) }) {
                continue
            }
            if compact.range(of: #"(?i)[A-Z]{1,5}[- ]?\d{1,4}[A-Z]?$"#, options: .regularExpression) != nil
                || compact.range(of: #"(?i)^[A-Z0-9-]{3,}$"#, options: .regularExpression) != nil
                || compact.range(of: #"^\d{2,4}$"#, options: .regularExpression) != nil {
                candidates.append(part)
                if compact != part {
                    candidates.append(compact)
                }
            }
        }

        return mergedImprintCodes(primary: [], fallback: candidates)
    }

    private static func normalizedSearchText(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "−", with: "")
            .replacingOccurrences(of: "ー", with: "")
            .replacingOccurrences(of: "－", with: "")
            .lowercased()
    }

    private static func absoluteRADARURL(for path: String) -> URL? {
        let cleaned = path.replacingOccurrences(of: "./", with: "")
        return URL(string: cleaned, relativeTo: radArBaseURL.appendingPathComponent("/siori/"))?.absoluteURL
    }

    private static func extractSection(_ html: String, id: String, next: String) -> String {
        let pattern: String
        if next.contains("script type=") {
            pattern = #"(?s)<h4 class="contents-title" id="\#(id)">.*?</h4>\s*<div class="contents-block">(.*?)<script type="text/javascript">"#
        } else {
            pattern = #"(?s)<h4 class="contents-title" id="\#(id)">.*?</h4>\s*<div class="contents-block">(.*?)<h4 class="contents-title" id="\#(next)">"#
        }
        guard let raw = html.captureFirst(pattern) else { return "" }
        return htmlText(from: raw)
    }

    private static func extractSubsection(_ html: String, id: String) -> String {
        let pattern = #"(?s)<b id="\#(id)">.*?</b></div>\s*<div class="contents-block"><div>(.*?)</div>"#
        guard let raw = html.captureFirst(pattern) else { return "" }
        return htmlText(from: raw)
    }

    private static func captureTableValue(_ html: String, header: String) -> String? {
        let escapedHeader = NSRegularExpression.escapedPattern(for: header)
        let pattern = #"(?s)<th>\#(escapedHeader)</th>\s*<td>(.*?)</td>"#
        return normalizedText(html.captureFirst(pattern).map(htmlText(from:)))
    }

    private static func captureOTCValue(_ html: String, title: String) -> String? {
        let escapedTitle = NSRegularExpression.escapedPattern(for: title)
        let pattern = #"(?s)<td class="title"[^>]*>\s*\#(escapedTitle).*?</td>\s*<td class="item">(.*?)</td>"#
        return normalizedText(html.captureFirst(pattern).map(htmlText(from:)))
    }

    private static func extractOTCIngredients(_ html: String) -> String {
        let pattern = #"(?s)<td class="title"[^>]*>\s*成分.*?</td>\s*<td class="item">(.*?)</td>"#
        guard let raw = html.captureFirst(pattern) else { return "" }
        return splitParagraphs(htmlText(from: raw)).joined(separator: "、")
    }

    private static func extractOTCSection(_ html: String, header: String) -> String {
        let escapedHeader = NSRegularExpression.escapedPattern(for: header)
        let pattern = #"(?s)<h4>\#(escapedHeader)</h4>\s*<p class="info">(.*?)</p>"#
        guard let raw = html.captureFirst(pattern) else { return "" }
        return htmlText(from: raw)
    }

    private static func extractPriceText(from html: String) -> String {
        let pattern = #"(?s)<h4 class="contents-title" id="products">.*?<table class="product_info">.*?<tr>\s*<td>.*?</td>\s*<td>.*?</td>\s*<td>.*?</td>\s*<td>.*?</td>\s*<td>(.*?)</td>"#
        return normalizedText(html.captureFirst(pattern).map(htmlText(from:))) ?? ""
    }

    private static func extractSimilarProductURL(from html: String, relativeTo base: URL) -> URL? {
        guard let href = html.captureFirst(#"href="(similar_product\?kegg_drug=[^"]+)""#) else {
            return nil
        }
        return URL(string: href, relativeTo: base)?.absoluteURL
    }

    private static func fetchGenericProducts(from url: URL?, genericName: String, brandName: String) async -> [Medicine.Pricing.PriceItem] {
        guard let url, !genericName.isEmpty else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(decoding: data, as: UTF8.self)
            return extractGenericProducts(from: html, genericName: genericName, brandName: brandName)
        } catch {
            return []
        }
    }

    private static func extractGenericProducts(from html: String, genericName: String, brandName: String) -> [Medicine.Pricing.PriceItem] {
        let pattern = #"(?s)<td class="data1"[^>]*>\s*<div>\s*<a href="japic_med\?japic_code=[^"]+">([^<]+)</a>\s*</div>\s*<div>\(([^<]+)\)</div>\s*</td>\s*<td class="data1">\s*<div>\s*<a href="japic_med\?japic_code=[^"]+">([^<]+)</a>\s*</div>(?:\s*<div>\(([^<]+)\)</div>)?\s*</td>\s*<td class="data1"[^>]*>(.*?)</td>"#
        var seen: Set<String> = []

        return html.captureGroups(pattern).compactMap { groups in
            guard groups.count >= 5 else { return nil }
            let summaryName = htmlText(from: groups[0])
            let maker = htmlText(from: groups[1])
            let productName = htmlText(from: groups[2])
            let marker = htmlText(from: groups[3])
            let priceText = htmlText(from: groups[4])

            guard isSameIngredientProduct(summaryName: summaryName, productName: productName, genericName: genericName),
                  isGenericProduct(productName: productName, marker: marker, brandName: brandName),
                  seen.insert(productName).inserted else {
                return nil
            }

            return Medicine.Pricing.PriceItem(
                name: productName,
                price: parsePriceValue(priceText) ?? 0,
                maker: maker
            )
        }
        .prefix(12)
        .map { $0 }
    }

    private static func isSameIngredientProduct(summaryName: String, productName: String, genericName: String) -> Bool {
        let ingredient = normalizedIngredientName(genericName)
        guard !ingredient.isEmpty else { return false }
        return normalizedIngredientName(summaryName).contains(ingredient)
            || normalizedIngredientName(productName).contains(ingredient)
            || ingredient.contains(normalizedIngredientName(summaryName))
    }

    private static func isGenericProduct(productName: String, marker: String, brandName: String) -> Bool {
        let normalizedProduct = normalizedForMatch(productName)
        let normalizedBrand = normalizedForMatch(brandName)
        guard normalizedBrand.isEmpty || !normalizedProduct.contains(normalizedBrand) else {
            return false
        }
        return marker.contains("後発品")
            || marker.contains("★")
            || productName.contains("「")
            || productName.contains("\"")
    }

    private static func extractPackageInsertURL(from html: String, relativeTo base: URL) -> URL? {
        let patterns = [
            #"href="([^"]+\.pdf[^"]*)">\s*添付文書"#,
            #"href="([^"]+\.pdf[^"]*)""#
        ]

        for pattern in patterns {
            if let href = html.captureFirst(pattern),
               let url = URL(string: href, relativeTo: base)?.absoluteURL {
                return url
            }
        }

        return nil
    }

    private static func fetchPackageInsertText(from url: URL?) async -> String? {
        guard let url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let document = PDFDocument(data: data), document.pageCount > 0 else {
                return nil
            }

            let text = (0..<document.pageCount)
                .compactMap { document.page(at: $0)?.string }
                .joined(separator: "\n")
            return sanitizeClinicalSection(reflowPackageInsertText(text))
        } catch {
            return nil
        }
    }

    private static func preferredPackageSection(
        pdfText: String?,
        headingNumbers: [String],
        fallback: String,
        maxItems: Int,
        separator: String = "。",
        contentFilter: ((String) -> Bool)? = nil
    ) -> String {
        let pdfSection = pdfText.flatMap {
            extractPackageInsertSection(from: $0, headingNumbers: headingNumbers)
        }
        let source = (pdfSection?.isEmpty == false) ? pdfSection! : fallback
        let filteredSource: String
        if let contentFilter {
            filteredSource = splitParagraphs(source)
                .filter(contentFilter)
                .joined(separator: "\n")
        } else {
            filteredSource = source
        }
        return summarizeClinicalText(filteredSource.isEmpty ? fallback : filteredSource, maxItems: maxItems, separator: separator)
    }

    private static func extractPackageInsertSection(from text: String, headingNumbers: [String]) -> String? {
        let normalized = reflowPackageInsertText(text)
        let lines = splitParagraphs(normalized)
        let targetNumbers = Set(headingNumbers)
        let targetMajorNumbers = Set(headingNumbers.map { majorHeadingNumber($0) })
        var isCapturing = false
        var captured: [String] = []

        for line in lines {
            let heading = packageHeadingNumber(in: line)

            if !isCapturing, let heading, targetNumbers.contains(heading) || targetMajorNumbers.contains(heading) {
                isCapturing = true
                if let content = lineWithoutPackageHeading(line), !isPackageHeadingTitle(content) {
                    captured.append(content)
                }
                continue
            }

            if isCapturing {
                if let heading {
                    let headingMajor = majorHeadingNumber(heading)
                    if !targetMajorNumbers.contains(headingMajor) {
                        break
                    }
                    if let content = lineWithoutPackageHeading(line), !isPackageHeadingTitle(content) {
                        captured.append(content)
                    }
                    continue
                }

                if !looksLikePackageHeaderFooter(line) {
                    captured.append(line)
                }
            }
        }

        let section = captured.joined(separator: "\n")
        return section.isEmpty ? nil : section
    }

    private static func extractStructuredPackageSections(from text: String?) -> [Medicine.ProInfo.DocumentSection] {
        guard let text, !text.isEmpty else { return [] }

        let lines = splitParagraphs(reflowPackageInsertText(text))
        var sections: [Medicine.ProInfo.DocumentSection] = []
        var currentTitle: String?
        var currentLines: [String] = []

        func flushCurrentSection() {
            guard let currentTitle, isDisplayablePackageSectionTitle(currentTitle) else {
                currentLines = []
                return
            }

            let bodyLines = currentLines
                .compactMap(sanitizedPackageSectionLine(_:))

            let uniqueLines = bodyLines.reduce(into: [String]()) { result, line in
                let normalizedLine = normalizedForMatch(line)
                if !normalizedLine.isEmpty && !result.contains(where: { normalizedForMatch($0) == normalizedLine }) {
                    result.append(line)
                }
            }

            let body = uniqueLines
                .prefix(12)
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard body.count >= 8 else {
                currentLines = []
                return
            }

            sections.append(.init(title: currentTitle, body: body))
            currentLines = []
        }

        for line in lines {
            if let heading = packageHeadingComponents(from: line) {
                flushCurrentSection()
                currentTitle = heading.title
                currentLines = []
                if let remainder = heading.remainder,
                   let sanitized = sanitizedPackageSectionLine(remainder) {
                    currentLines.append(sanitized)
                }
                continue
            }

            guard currentTitle != nil else { continue }
            if let sanitized = sanitizedPackageSectionLine(line) {
                currentLines.append(sanitized)
            }
        }

        flushCurrentSection()

        return Array(sections.prefix(8))
    }

    private static func packageHeadingComponents(from line: String) -> (title: String, remainder: String?)? {
        let raw = (lineWithoutPackageHeading(line) ?? line)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let exactTitles = packageSectionTitles.sorted { $0.count > $1.count }
        let normalizedRaw = normalizedForMatch(raw)

        for title in exactTitles {
            let normalizedTitle = normalizedForMatch(title)
            if normalizedRaw == normalizedTitle {
                return (title, nil)
            }
            if normalizedRaw.hasPrefix(normalizedTitle) {
                let remainder = raw.dropFirst(title.count).trimmingCharacters(in: .whitespacesAndNewlines)
                return (title, remainder.isEmpty ? nil : remainder)
            }
        }

        return nil
    }

    private static var packageSectionTitles: [String] {
        [
            "警告",
            "禁忌",
            "効能又は効果",
            "効能又は効果に関連する注意",
            "用法及び用量",
            "用法及び用量に関連する注意",
            "重要な基本的注意",
            "特定の背景を有する患者に関する注意",
            "高齢者",
            "妊婦",
            "授乳婦",
            "小児等",
            "相互作用",
            "副作用",
            "重大な副作用",
            "その他の副作用",
            "薬効薬理",
            "作用機序",
            "薬物動態",
            "臨床成績",
            "適用上の注意",
            "取扱い上の注意"
        ]
    }

    private static func isDisplayablePackageSectionTitle(_ title: String) -> Bool {
        let normalized = normalizedForMatch(title)
        let excluded = [
            "包装",
            "主要文献",
            "文献請求先及び問い合わせ先",
            "製造販売業者等",
            "組成性状"
        ].map(normalizedForMatch)
        return !excluded.contains(normalized)
    }

    private static func sanitizedPackageSectionLine(_ line: String) -> String? {
        guard !looksLikePackageHeaderFooter(line) else { return nil }

        let cleaned = normalizeJapaneseSpacing(line)
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\d+(\.\d+)*\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[（(]?\d+[）)]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[・\-●■□※]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.count >= 2 else { return nil }
        guard !isPackageHeadingTitle(cleaned) else { return nil }
        guard !normalizedForMatch(cleaned).allSatisfy({ $0.isNumber }) else { return nil }
        return cleaned
    }

    private static func normalizePackageInsertText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: #"([。；])\s+"#, with: "$1\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n{2,}"#, with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func reflowPackageInsertText(_ text: String) -> String {
        let lines = normalizePackageInsertText(text)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var merged: [String] = []
        for line in lines {
            if shouldStartNewPackageLine(line, previous: merged.last) {
                merged.append(line)
            } else if let last = merged.popLast() {
                merged.append(joinJapaneseText(last, line))
            } else {
                merged.append(line)
            }
        }

        return merged.joined(separator: "\n")
    }

    private static func shouldStartNewPackageLine(_ line: String, previous: String?) -> Bool {
        guard let previous else { return true }
        if packageHeadingNumber(in: line) != nil { return true }
        if line.range(of: #"^[（(]?\d+[）)]"#, options: .regularExpression) != nil { return true }
        if line.range(of: #"^[・●■□※]"#, options: .regularExpression) != nil { return true }
        if isPackageHeadingTitle(line) { return true }
        if previous.hasSuffix("。") || previous.hasSuffix("；") || previous.hasSuffix("：") || previous.hasSuffix(":") { return true }
        return false
    }

    private static func joinJapaneseText(_ lhs: String, _ rhs: String) -> String {
        let left = normalizeJapaneseSpacing(lhs.trimmingCharacters(in: .whitespacesAndNewlines))
        let right = normalizeJapaneseSpacing(rhs.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !left.isEmpty else { return right }
        guard !right.isEmpty else { return left }

        if left.hasSuffix("-") {
            return normalizeJapaneseSpacing(String(left.dropLast()) + right)
        }
        if shouldJoinWithoutSpace(left, right) {
            return normalizeJapaneseSpacing(left + right)
        }
        return normalizeJapaneseSpacing(left + " " + right)
    }

    private static func shouldJoinWithoutSpace(_ lhs: String, _ rhs: String) -> Bool {
        guard let last = lhs.unicodeScalars.last, let first = rhs.unicodeScalars.first else {
            return true
        }
        return isJapaneseScalar(last) || isJapaneseScalar(first)
    }

    private static func isJapaneseScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3040...0x30FF, 0x3400...0x9FFF, 0xFF00...0xFFEF:
            return true
        default:
            return false
        }
    }

    private static func packageHeadingNumber(in line: String) -> String? {
        let pattern = #"^\s*(\d{1,2}(?:\.\d+)?)\s*[\.．\s]"#
        return line.captureFirst(pattern)
    }

    private static func lineWithoutPackageHeading(_ line: String) -> String? {
        let cleaned = line
            .replacingOccurrences(of: #"^\s*\d{1,2}(?:\.\d+)?\s*[\.．]?\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func majorHeadingNumber(_ heading: String) -> String {
        heading.components(separatedBy: ".").first ?? heading
    }

    private static func isPackageHeadingTitle(_ line: String) -> Bool {
        let normalized = normalizedForMatch(line)
        let titles = [
            "警告",
            "禁忌",
            "組成性状",
            "効能又は効果",
            "効能又は効果に関連する注意",
            "効能効果に関連する注意",
            "用法及び用量",
            "用法及び用量に関連する注意",
            "重要な基本的注意",
            "特定の背景を有する患者に関する注意",
            "高齢者",
            "妊婦",
            "授乳婦",
            "小児等",
            "相互作用",
            "副作用",
            "重大な副作用",
            "その他の副作用",
            "薬効薬理",
            "作用機序",
            "薬物動態",
            "臨床成績",
            "適用上の注意",
            "取扱い上の注意",
            "包装",
            "主要文献",
            "文献請求先及び問い合わせ先",
            "製造販売業者等"
        ].map(normalizedForMatch)
        return titles.contains(normalized)
    }

    private static func looksLikePackageHeaderFooter(_ line: String) -> Bool {
        let markers = ["日本標準商品分類番号", "承認番号", "薬価収載", "販売開始", "貯法", "有効期間", "添付文書", "改訂"]
        if markers.contains(where: { line.contains($0) }) {
            return true
        }
        return line.range(of: #"^-\s*\d+\s*-$"#, options: .regularExpression) != nil
    }

    private static func extractAdverseEffects(from html: String, fallbackText: String) -> [Medicine.AdverseEffect] {
        var effects = majorAdverseEffects(from: html)
        if effects.count < 5 {
            effects.append(contentsOf: tableAdverseEffects(from: html))
        }
        if effects.isEmpty {
            effects = fallbackAdverseEffects(from: fallbackText)
        }

        var seen: Set<String> = []
        return effects.filter { effect in
            let key = normalizedForMatch(effect.name)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private static func mergeAdverseEffects(primary: [Medicine.AdverseEffect], secondary: [Medicine.AdverseEffect]) -> [Medicine.AdverseEffect] {
        var seen: Set<String> = []
        var merged: [Medicine.AdverseEffect] = []

        for effect in primary + secondary {
            let cleanedEffect = cleanedAdverseEffect(effect)
            let key = normalizedForMatch(cleanedEffect.name)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            merged.append(cleanedEffect)
        }

        return Array(merged.prefix(10))
    }

    private static func majorAdverseEffects(from html: String) -> [Medicine.AdverseEffect] {
        let pattern = #"(?s)<b id="par-11_1_\d+">([^<]+)</b>（([^）]+)）(.*?)(?=<div class="contents-title"|<h5 class="contents-title" id="par-11_2">)"#
        return html.captureGroups(pattern).flatMap { groups in
            guard groups.count >= 3 else { return [Medicine.AdverseEffect]() }
            let primaryName = cleanAdverseEffectLabel(htmlText(from: groups[0]))
            let primaryFrequency = normalizedText(htmlText(from: groups[1])) ?? "頻度不明"
            let detail = cleanAdverseEffectDetail(htmlText(from: groups[2]))

            var items: [Medicine.AdverseEffect] = []
            if !primaryName.isEmpty {
                items.append(cleanedAdverseEffect(.init(name: primaryName, frequency: primaryFrequency, detail: detail)))
            }

            let extraPattern = #"<b>([^<]+)</b>（([^）]+)）"#
            for extra in groups[2].captureGroups(extraPattern) {
                guard extra.count >= 2 else { continue }
                let name = cleanAdverseEffectLabel(htmlText(from: extra[0]))
                let frequency = normalizedText(htmlText(from: extra[1])) ?? "頻度不明"
                guard !name.isEmpty else { continue }
                items.append(cleanedAdverseEffect(.init(name: name, frequency: frequency, detail: detail)))
            }
            return items
        }
    }

    private static func tableAdverseEffects(from html: String) -> [Medicine.AdverseEffect] {
        let sectionPattern = #"(?s)<h5 class="contents-title" id="par-11_2">.*?</h5>\s*<div class="contents-block"><div class="tbl-set"><table.*?>(.*?)</table>"#
        guard let tableHTML = html.captureFirst(sectionPattern) else { return [] }
        let rowPattern = #"(?s)<tr>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*</tr>"#
        let rows = tableHTML.captureGroups(rowPattern)

        var effects: [Medicine.AdverseEffect] = []
        for row in rows.dropFirst() {
            guard row.count >= 4 else { continue }
            let system = cleanAdverseEffectLabel(htmlText(from: row[0]))
            let columns = [
                ("0.1〜2％未満", row[1]),
                ("0.1％未満", row[2]),
                ("頻度不明", row[3])
            ]
            for (frequency, raw) in columns {
                let items = splitAdverseEffectItems(htmlText(from: raw))
                for item in items.prefix(8) {
                    effects.append(cleanedAdverseEffect(.init(name: item, frequency: frequency, detail: adverseEffectDetail(system: system, frequency: frequency))))
                }
            }
        }
        return effects
    }

    private static func adverseEffectDetail(system: String, frequency: String) -> String {
        if system.isEmpty {
            return ""
        }
        return "\(system)に分類される副作用です。発現頻度: \(frequency)。"
    }

    private static func fallbackAdverseEffects(from text: String) -> [Medicine.AdverseEffect] {
        splitParagraphs(text)
            .prefix(6)
            .compactMap { line in
                let name = adverseEffectName(from: line)
                guard !name.isEmpty else { return nil }
                return cleanedAdverseEffect(.init(
                    name: name,
                    frequency: line.contains("頻度不明") ? "頻度不明" : "記載あり",
                    detail: adverseEffectDetail(from: line, name: name)
                ))
            }
            .filter { !$0.name.isEmpty }
    }

    private static func adverseEffectName(from line: String) -> String {
        let cleanedLine = cleanAdverseEffectDetail(normalizeJapaneseSpacing(line))
        if looksLikeAdverseHeading(cleanedLine) {
            return ""
        }
        if let first = cleanedLine.captureFirst(#"^([^。．：:]{2,30})[：:]"#) {
            return cleanAdverseEffectLabel(first)
        }
        if let first = cleanedLine.captureFirst(#"^([^（(]{2,30})[（(]"#) {
            return cleanAdverseEffectLabel(first)
        }
        let symptomCandidates = cleanedLine
            .components(separatedBy: CharacterSet(charactersIn: "、,。;；"))
            .map(cleanAdverseEffectLabel)
            .filter { !$0.isEmpty && !looksLikeAdverseHeading($0) }
        return symptomCandidates.first ?? ""
    }

    private static func adverseEffectDetail(from line: String, name: String) -> String {
        let detail = cleanAdverseEffectDetail(normalizeJapaneseSpacing(line))
        let normalizedName = normalizedForMatch(name)
        let normalizedDetail = normalizedForMatch(detail)
        if normalizedName == normalizedDetail {
            return ""
        }
        return detail
    }

    private static func looksLikeAdverseHeading(_ text: String) -> Bool {
        let normalized = normalizedForMatch(text)
        let headings = [
            "重大な副作用",
            "その他の副作用",
            "副作用",
            "精神神経系",
            "消化器",
            "過敏症",
            "肝臓",
            "腎臓",
            "血液",
            "循環器"
        ].map(normalizedForMatch)
        return headings.contains(normalized)
    }

    private static func patientSideEffects(from effects: [Medicine.AdverseEffect]) -> [Medicine.SideEffect] {
        effects.prefix(4).map { effect in
            Medicine.SideEffect(
                icon: sideEffectIcon(for: effect.name),
                name: effect.name,
                detail: effect.detail
            )
        }
    }

    private static func otcSideEffects(from precautions: String) -> [Medicine.AdverseEffect] {
        let lines = splitParagraphs(precautions)
        let matched = lines.filter { line in
            ["発疹", "かゆみ", "吐き気", "めまい", "眠気", "副作用"].contains(where: { line.contains($0) })
        }
        return matched.prefix(5).map {
            .init(name: cleanAdverseEffectLabel($0.components(separatedBy: "、").first ?? $0), frequency: "注意喚起", detail: $0)
        }
    }

    private static func pricing(for fetched: PMDAFetchedDrug, brandName: String, maker: String) -> Medicine.Pricing {
        let parsedPrice = parsePriceValue(fetched.priceText)
        return Medicine.Pricing(
            brand: .init(name: brandName, price: parsedPrice ?? 0, maker: maker),
            generics: fetched.genericProducts,
            unit: parsePriceUnit(fetched.priceText),
            source: "KEGG MEDICUS 公開医薬品情報",
            patientBurden30: parsedPrice == nil ? "薬価情報は公開ページから取得できませんでした" : "実際の患者負担額は用量・日数に応じて計算してください",
            note: fetched.priceText.isEmpty ? "薬価情報は公開ページから取得できませんでした。" : "取得薬価: \(fetched.priceText)"
        )
    }

    private static func mergedPricing(base: Medicine.Pricing, fetched: PMDAFetchedDrug) -> Medicine.Pricing {
        let mergedGenerics = mergedGenericProducts(base.generics, fetched.genericProducts)
        guard let parsedPrice = parsePriceValue(fetched.priceText), parsedPrice > 0 else {
            return Medicine.Pricing(
                brand: base.brand,
                generics: mergedGenerics,
                unit: base.unit,
                source: base.source,
                patientBurden30: base.patientBurden30,
                note: base.note
            )
        }

        return Medicine.Pricing(
            brand: .init(name: base.brand.name, price: parsedPrice, maker: fetched.manufacturer.isEmpty ? base.brand.maker : fetched.manufacturer),
            generics: mergedGenerics,
            unit: parsePriceUnit(fetched.priceText),
            source: "KEGG MEDICUS 公開医薬品情報",
            patientBurden30: "実際の患者負担額は用量・日数に応じて計算してください",
            note: "取得薬価: \(fetched.priceText)"
        )
    }

    private static func mergedGenericProducts(_ base: [Medicine.Pricing.PriceItem], _ fetched: [Medicine.Pricing.PriceItem]) -> [Medicine.Pricing.PriceItem] {
        var seen: Set<String> = []
        return (fetched + base).filter { item in
            seen.insert(normalizedForMatch(item.name)).inserted
        }
    }

    private static func parsePriceValue(_ text: String) -> Double? {
        guard let raw = text.captureFirst(#"([0-9]+(?:\.[0-9]+)?)円"#) else { return nil }
        return Double(raw)
    }

    private static func parsePriceUnit(_ text: String) -> String {
        guard let unit = text.captureFirst(#"円[／/]([^ ]+)"#) else { return "単位" }
        return unit
    }

    private static func importedMedicineID(brandName: String, genericName: String, maker: String) -> Int {
        let source = normalizedForMatch([brandName, genericName, maker].joined(separator: "|"))
        var hash = 5381
        for scalar in source.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return 9_000_000 + abs(hash % 900_000_000)
    }

    private static func splitAdverseEffectItems(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "<sup>.*?</sup>", with: "", options: .regularExpression)
            .replacingOccurrences(of: #"注\d*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .components(separatedBy: CharacterSet(charactersIn: "、,，\n"))
            .compactMap { normalizedText($0) }
            .map(cleanAdverseEffectLabel)
            .filter { item in
                !item.isEmpty
                    && item != "注）"
                    && !looksLikeAdverseHeading(item)
                    && !item.contains("発現頻度")
                    && !item.contains("使用成績調査")
            }
    }

    private static func cleanAdverseEffectLabel(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"^\d+(\.\d+)+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"注）"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanAdverseEffectDetail(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\d+(\.\d+)+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanedAdverseEffect(_ effect: Medicine.AdverseEffect) -> Medicine.AdverseEffect {
        let name = cleanAdverseEffectLabel(normalizeJapaneseSpacing(effect.name))
        let detail = cleanAdverseEffectDetail(normalizeJapaneseSpacing(effect.detail))
        let normalizedName = normalizedForMatch(name)
        let normalizedDetail = normalizedForMatch(detail)
        let shouldHideDetail = normalizedDetail.isEmpty
            || normalizedName == normalizedDetail
            || (normalizedDetail.hasPrefix(normalizedName) && normalizedDetail.count <= normalizedName.count + 8)
            || (normalizedDetail.contains(normalizedName) && normalizedDetail.count <= normalizedName.count * 2)

        return Medicine.AdverseEffect(
            name: name,
            frequency: normalizeJapaneseSpacing(effect.frequency).ifEmpty("記載あり"),
            detail: shouldHideDetail ? "" : detail
        )
    }

    private static func sideEffectIcon(for name: String) -> String {
        if name.contains("発疹") || name.contains("蕁麻疹") || name.contains("そう痒") {
            return "🩹"
        }
        if name.contains("胃") || name.contains("腹") || name.contains("吐") || name.contains("下痢") {
            return "🤢"
        }
        if name.contains("眠気") || name.contains("めまい") || name.contains("しびれ") {
            return "😵"
        }
        if name.contains("浮腫") || name.contains("動悸") || name.contains("血圧") {
            return "💓"
        }
        return "⚠️"
    }

    private static func score(_ entry: KEGGSearchEntry, for query: String) -> Int {
        let normalizedQuery = normalizedForMatch(query)
        let brand = normalizedForMatch(entry.brandName)
        let generic = normalizedForMatch(entry.genericName)
        let drugClass = normalizedForMatch(entry.drugClass)

        var score = 0
        if brand == normalizedQuery { score += 1000 }
        if generic == normalizedQuery { score += 900 }
        if brand.contains(normalizedQuery) { score += 400 }
        if generic.contains(normalizedQuery) { score += 350 }
        if drugClass.contains(normalizedQuery) { score += 100 }
        if !entry.rx { score -= 10 }
        if brand.contains("錠") { score += 40 }
        if brand.contains("カプセル") { score += 30 }
        if brand.contains("散") || brand.contains("細粒") { score += 15 }
        if brand.contains("テープ") || brand.contains("パップ") || brand.contains("ゲル") || brand.contains("外用") { score -= 50 }
        return score
    }

    private static func sanitizeClinicalSection(_ text: String) -> String {
        splitParagraphs(text)
            .filter { line in
                !looksLikeContactInfo(line)
            }
            .joined(separator: "\n")
    }

    private static func summarizeClinicalText(_ text: String, maxItems: Int, separator: String = "。") -> String {
        let items = clinicalItems(from: text, maxItems: maxItems)
        if separator == "\n" {
            return items.joined(separator: "\n")
        }
        return items.map(ensureSentenceEnding).joined(separator: " ")
    }

    private static func clinicalItems(from text: String, maxItems: Int) -> [String] {
        let rawItems = splitParagraphs(text).flatMap(splitLongClinicalLine)
        var seen: Set<String> = []

        let cleanedItems: [String] = rawItems.compactMap { raw -> String? in
            let cleaned = cleanClinicalDisplayLine(raw)
            let key = normalizedForMatch(cleaned)
            guard !cleaned.isEmpty, key.count > 2, !seen.contains(key), !looksLikeContactInfo(cleaned), !looksLikeClinicalHeading(cleaned) else {
                return nil
            }
            seen.insert(key)
            return cleaned
        }

        return Array(cleanedItems.prefix(maxItems))
    }

    private static func splitLongClinicalLine(_ line: String) -> [String] {
        let normalized = normalizeJapaneseSpacing(reflowDisplayText(line)).replacingOccurrences(of: "；", with: "。")
        if normalized.count <= 90 {
            return [normalized]
        }

        let sentencePieces = normalized
            .components(separatedBy: CharacterSet(charactersIn: "。;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sentencePieces.isEmpty ? [normalized] : sentencePieces
    }

    private static func cleanClinicalDisplayLine(_ text: String) -> String {
        normalizeJapaneseSpacing(reflowDisplayText(text))
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^第\d+章\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\d+(\.\d+)*\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[（(]?\d+[）)]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[・\-●]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"注[）)]?\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func looksLikeClinicalHeading(_ line: String) -> Bool {
        let normalized = normalizedForMatch(line)
        let headings = [
            "作用機序",
            "効能又は効果",
            "用法及び用量",
            "禁忌",
            "重要な基本的注意",
            "副作用",
            "薬効薬理",
            "薬物動態",
            "包装"
        ].map(normalizedForMatch)
        return headings.contains(normalized)
    }

    private static func isMechanismLine(_ line: String) -> Bool {
        let normalized = normalizedForMatch(line)
        guard !normalized.isEmpty else { return false }

        let excludedFragments = [
            "副作用",
            "有害事象",
            "悪心",
            "傾眠",
            "頭痛",
            "投与群",
            "プラセボ",
            "例",
            "％",
            "%",
            "信頼区間",
            "p値",
            "LSAS",
            "MADRS",
            "HAM",
            "試験",
            "臨床成績",
            "比較",
            "スコア"
        ].map(normalizedForMatch)

        if excludedFragments.contains(where: { normalized.contains($0) }) {
            return false
        }

        let includedFragments = [
            "作用機序",
            "薬理作用",
            "受容体",
            "再取り込み",
            "阻害",
            "親和性",
            "セロトニン",
            "ノルアドレナリン",
            "ドパミン",
            "GABA",
            "COX",
            "プロスタグランジン",
            "アンジオテンシン",
            "チャネル",
            "酵素"
        ].map(normalizedForMatch)

        return includedFragments.contains(where: { normalized.contains($0) })
    }

    private static func isInteractionWarningLine(_ line: String) -> Bool {
        let normalized = normalizedForMatch(line)
        guard !normalized.isEmpty else { return false }

        let excludedFragments = [
            "日本標準商品分類番号",
            "承認番号",
            "薬価収載",
            "販売開始",
            "貯法",
            "有効期間",
            "改訂",
            "包装",
            "劇薬",
            "処方箋医薬品"
        ].map(normalizedForMatch)

        if excludedFragments.contains(where: { normalized.contains($0) }) {
            return false
        }

        let includedFragments = [
            "相互作用",
            "併用",
            "併用注意",
            "併用禁忌",
            "他の薬",
            "市販薬",
            "サプリ",
            "アルコール",
            "飲酒",
            "CYP",
            "吸収",
            "血中濃度",
            "作用を増強",
            "作用を減弱"
        ].map(normalizedForMatch)

        return includedFragments.contains(where: { normalized.contains($0) })
    }

    private static func summarizeInteractionWarnings(from text: String) -> String {
        let lines = splitParagraphs(text)
            .filter(isInteractionWarningLine(_:))
            .filter { !looksLikePackageHeaderFooter($0) }

        guard !lines.isEmpty else { return "" }
        return summarizeClinicalText(lines.joined(separator: "\n"), maxItems: 4, separator: "\n")
    }

    private static func reflowDisplayText(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\s*\n\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"([。；:：])"#, with: "$1\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n{2,}"#, with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeJapaneseSpacing(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"(?<=[ぁ-んァ-ヶ一-龠])\s+(?=[ぁ-んァ-ヶ一-龠])"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?<=[ぁ-んァ-ヶ一-龠])\s+(?=[、。，．・）」』])"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?<=[（「『])\s+(?=[ぁ-んァ-ヶ一-龠A-Za-z0-9])"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+([、。，．・）」』])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"([（「『])\s+"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func ensureSentenceEnding(_ text: String) -> String {
        guard let last = text.last else { return text }
        if ["。", "、", ".", "！", "？"].contains(last) {
            return text
        }
        return "\(text)。"
    }

    private static func looksLikeContactInfo(_ line: String) -> Bool {
        let markers = [
            "株式会社", "製造販売元", "問い合わせ先", "文献請求先", "電話", "〒", "東京都", "大阪市", "中央区",
            "日本標準商品分類番号", "承認番号", "薬価収載", "販売開始", "貯法", "有効期間", "添付文書", "改訂",
            "劇薬", "処方箋医薬品"
        ]
        if markers.contains(where: { line.contains($0) }) {
            return true
        }
        return line.range(of: #"\d{2,4}-\d{2,4}-\d{3,4}"#, options: .regularExpression) != nil
    }

    private static func htmlText(from html: String) -> String {
        html
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "</div>", with: "\n")
            .replacingOccurrences(of: "</li>", with: "\n")
            .replacingOccurrences(of: "</tr>", with: "\n")
            .replacingOccurrences(of: "</h4>", with: "\n")
            .replacingOccurrences(of: "</h5>", with: "\n")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&times;", with: "×")
            .replacingOccurrences(of: "&rarr;", with: "→")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#12306;", with: "〒")
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\n"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n{2,}"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitParagraphs(_ text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { normalizedText($0) ?? "" }
            .filter { !$0.isEmpty }
    }

    private static func firstMeaningfulLine(in text: String) -> String? {
        let lines = splitParagraphs(text)
        let headingFragments = [
            "製造販売元",
            "製造販売業者等",
            "文献請求先",
            "製品情報問い合わせ先"
        ]

        for line in lines {
            if headingFragments.contains(where: { line.contains($0) }) {
                continue
            }
            if line.hasPrefix("26.") || line.hasPrefix("24.") {
                continue
            }
            return line
        }

        return lines.first
    }

    private static func normalizedQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func aliasQueries(for query: String) -> [String] {
        let aliasMap: [String: [String]] = [
            "タスモリン": ["ビペリデン", "ビペリデン塩酸塩", "タスモリン錠1mg"],
            "タスモリン錠1mg": ["ビペリデン", "ビペリデン塩酸塩", "タスモリン"],
            "ロヒプノール": ["サイレース", "サイレース錠1mg", "サイレース錠2mg", "フルニトラゼパム"],
            "ロヒプノール錠": ["サイレース", "サイレース錠1mg", "サイレース錠2mg", "フルニトラゼパム"],
            "フルニトラゼパム": ["サイレース", "サイレース錠1mg", "サイレース錠2mg"],
            "ソリタT1": ["ソリタ－T1号輸液", "ソリタ-T1号輸液", "ソリタ T1"],
            "ソリタT2": ["ソリタ－T2号輸液", "ソリタ-T2号輸液", "ソリタ T2"],
            "ソリタT3": ["ソリタ－T3号輸液", "ソリタ-T3号輸液", "ソリタ T3"],
            "ソリタT3G": ["ソリタ－T3号G輸液", "ソリタ-T3号G輸液", "ソリタ T3G"],
            "ソリタT4": ["ソリタ－T4号輸液", "ソリタ-T4号輸液", "ソリタ T4"]
        ]

        let trimmed = normalizedQuery(query)
        return aliasMap[trimmed] ?? []
    }

    private static func normalizedForMatch(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
    }

    private static func normalizedIngredientName(_ text: String) -> String {
        var normalized = normalizedForMatch(text)
        let removableTerms = [
            "水和物", "塩酸塩", "硫酸塩", "リン酸塩", "臭化水素酸塩", "メタンスルホン酸塩",
            "トシル酸塩", "マレイン酸塩", "フマル酸塩", "ナトリウム", "カリウム", "カルシウム",
            "Na", "K", "Ca"
        ]
        for term in removableTerms {
            normalized = normalized.replacingOccurrences(of: normalizedForMatch(term), with: "")
        }
        return normalized
    }

    private static func normalizedText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func displayCategoryLabel(_ category: String, fallback: String) -> String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCategory.isEmpty {
            return fallback.isEmpty ? "治療薬" : fallback
        }

        let internalLabels = ["外部DB取得", "PMDA取得", "医薬品DB取得"]
        if internalLabels.contains(trimmedCategory) {
            return fallback.isEmpty ? "治療薬" : fallback
        }

        return trimmedCategory
    }
}

private extension String {
    func captureFirst(_ pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range),
              match.numberOfRanges > 1,
              let matchRange = Range(match.range(at: 1), in: self) else { return nil }
        return String(self[matchRange])
    }

    func captureGroups(_ pattern: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, options: [], range: range).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return (1..<match.numberOfRanges).compactMap { index in
                guard let groupRange = Range(match.range(at: index), in: self) else { return nil }
                return String(self[groupRange])
            }
        }
    }

    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
