import SwiftUI

struct DrugManufacturer: Identifiable {
    let id: String
    let name: String
    let kana: String
    let urlString: String
    let summary: String
    let focusAreas: [String]
    let representativeMedicines: [String]

    var url: URL? {
        URL(string: urlString)
    }
}

private let manufacturerDatabase: [DrugManufacturer] = [
    .init(
        id: "daiichi-sankyo",
        name: "第一三共",
        kana: "だいいちさんきょう",
        urlString: "https://www.daiichisankyo.co.jp/",
        summary: "循環器、疼痛、感染症、がん領域などを扱う国内大手製薬企業です。",
        focusAreas: ["循環器", "疼痛", "感染症", "がん"],
        representativeMedicines: ["ロキソニン", "オルメテック", "メマリー", "プラスグレル"]
    ),
    .init(
        id: "takeda",
        name: "武田薬品工業",
        kana: "たけだやくひんこうぎょう",
        urlString: "https://www.takeda.com/ja-jp/",
        summary: "消化器、希少疾患、血漿分画製剤、オンコロジーなどを重点領域とする製薬企業です。",
        focusAreas: ["消化器", "希少疾患", "血液", "がん"],
        representativeMedicines: ["タケキャブ", "アジルバ", "ベクティビックス", "エンタイビオ"]
    ),
    .init(
        id: "astellas",
        name: "アステラス製薬",
        kana: "あすてらすせいやく",
        urlString: "https://www.astellas.com/jp/",
        summary: "泌尿器、移植、感染症、がん領域などで多くの医療用医薬品を展開しています。",
        focusAreas: ["泌尿器", "移植", "感染症", "がん"],
        representativeMedicines: ["ハルナール", "ベタニス", "プログラフ", "イクスタンジ"]
    ),
    .init(
        id: "otsuka",
        name: "大塚製薬",
        kana: "おおつかせいやく",
        urlString: "https://www.otsuka.co.jp/",
        summary: "精神神経、循環器、輸液・栄養関連など幅広い領域の医薬品を扱います。",
        focusAreas: ["精神神経", "循環器", "輸液", "栄養"],
        representativeMedicines: ["エビリファイ", "レキサルティ", "サムスカ", "ポカリスエット"]
    ),
    .init(
        id: "eisai",
        name: "エーザイ",
        kana: "えーざい",
        urlString: "https://www.eisai.co.jp/",
        summary: "認知症、神経、消化器、がん領域などを中心に医薬品を提供しています。",
        focusAreas: ["認知症", "神経", "消化器", "がん"],
        representativeMedicines: ["アリセプト", "レンビマ", "パリエット", "フィコンパ"]
    ),
    .init(
        id: "chugai",
        name: "中外製薬",
        kana: "ちゅうがいせいやく",
        urlString: "https://www.chugai-pharm.co.jp/",
        summary: "抗体医薬品やがん、免疫、血液領域に強みを持つ製薬企業です。",
        focusAreas: ["がん", "免疫", "血液", "抗体医薬"],
        representativeMedicines: ["アクテムラ", "アレセンサ", "ヘムライブラ", "エンスプリング"]
    ),
    .init(
        id: "shionogi",
        name: "塩野義製薬",
        kana: "しおのぎせいやく",
        urlString: "https://www.shionogi.com/jp/ja/",
        summary: "感染症、疼痛、中枢神経などの領域で医療用医薬品を展開しています。",
        focusAreas: ["感染症", "疼痛", "中枢神経"],
        representativeMedicines: ["ゾコーバ", "サインバルタ", "クレストール", "フロモックス"]
    ),
    .init(
        id: "tanabe",
        name: "田辺三菱製薬",
        kana: "たなべみつびしせいやく",
        urlString: "https://www.mt-pharma.co.jp/",
        summary: "免疫炎症、中枢神経、糖尿病などの領域で医療用医薬品を扱います。",
        focusAreas: ["免疫炎症", "中枢神経", "糖尿病"],
        representativeMedicines: ["タスモリン", "レミケード", "テネリア", "カナグル"]
    ),
    .init(
        id: "ono",
        name: "小野薬品工業",
        kana: "おのやくひんこうぎょう",
        urlString: "https://www.ono-pharma.com/ja",
        summary: "がん免疫療法、糖尿病、消化器などの領域で医薬品を展開しています。",
        focusAreas: ["がん", "免疫", "糖尿病", "消化器"],
        representativeMedicines: ["オプジーボ", "グラクティブ", "フォシーガ", "リカルボン"]
    ),
    .init(
        id: "kyowa-kirin",
        name: "協和キリン",
        kana: "きょうわきりん",
        urlString: "https://www.kyowakirin.co.jp/",
        summary: "腎、免疫、がん、希少疾患領域などの医療用医薬品を扱います。",
        focusAreas: ["腎", "免疫", "がん", "希少疾患"],
        representativeMedicines: ["ネスプ", "ジーラスタ", "クリースビータ", "オルケディア"]
    ),
    .init(
        id: "taisho",
        name: "大正製薬",
        kana: "たいしょうせいやく",
        urlString: "https://www.taisho.co.jp/",
        summary: "OTC医薬品、セルフメディケーション、感染症・生活習慣病関連製品などを扱います。",
        focusAreas: ["OTC", "かぜ薬", "胃腸薬", "生活習慣病"],
        representativeMedicines: ["パブロン", "リアップ", "ナロン", "クラリス"]
    ),
    .init(
        id: "sawai",
        name: "沢井製薬",
        kana: "さわいせいやく",
        urlString: "https://www.sawai.co.jp/",
        summary: "ジェネリック医薬品を中心に、多くの成分・剤形を供給しています。",
        focusAreas: ["ジェネリック", "生活習慣病", "疼痛", "感染症"],
        representativeMedicines: ["ロキソプロフェンNa「サワイ」", "アムロジピン「サワイ」", "レボフロキサシン「サワイ」"]
    ),
    .init(
        id: "towa",
        name: "東和薬品",
        kana: "とうわやくひん",
        urlString: "https://www.towayakuhin.co.jp/",
        summary: "ジェネリック医薬品を中心に、飲みやすさや識別性にも配慮した製品を展開しています。",
        focusAreas: ["ジェネリック", "生活習慣病", "循環器", "精神神経"],
        representativeMedicines: ["ロキソプロフェンNa「トーワ」", "アムロジピン「トーワ」", "エスシタロプラム「トーワ」"]
    ),
    .init(
        id: "nichiko",
        name: "日医工",
        kana: "にちいこう",
        urlString: "https://www.nichiiko.co.jp/",
        summary: "ジェネリック医薬品を中心に、医療現場向け製品を幅広く扱います。",
        focusAreas: ["ジェネリック", "注射薬", "生活習慣病"],
        representativeMedicines: ["アムロジピン「日医工」", "ロスバスタチン「日医工」", "レバミピド「日医工」"]
    ),
    .init(
        id: "viatris",
        name: "ヴィアトリス製薬",
        kana: "ゔぃあとりすせいやく",
        urlString: "https://www.viatris.jp/",
        summary: "先発医薬品とジェネリック医薬品の両方を扱い、循環器や精神神経など幅広い領域をカバーします。",
        focusAreas: ["循環器", "精神神経", "感染症", "ジェネリック"],
        representativeMedicines: ["ノルバスク", "リピトール", "ジェイゾロフト", "セレコックス"]
    ),
    .init(
        id: "pfizer",
        name: "ファイザー",
        kana: "ふぁいざー",
        urlString: "https://www.pfizer.co.jp/",
        summary: "感染症、ワクチン、がん、炎症・免疫など幅広い領域の医薬品を扱います。",
        focusAreas: ["ワクチン", "感染症", "がん", "免疫"],
        representativeMedicines: ["リリカ", "エリキュース", "ジスロマック", "コミナティ"]
    ),
    .init(
        id: "novartis",
        name: "ノバルティスファーマ",
        kana: "のばるてぃすふぁーま",
        urlString: "https://www.novartis.com/jp-ja/",
        summary: "循環器、眼科、免疫、神経、がん領域などを中心に医薬品を展開しています。",
        focusAreas: ["循環器", "眼科", "免疫", "がん"],
        representativeMedicines: ["ディオバン", "エンレスト", "コセンティクス", "ジレニア"]
    ),
    .init(
        id: "msd",
        name: "MSD",
        kana: "えむえすでぃー",
        urlString: "https://www.msd.co.jp/",
        summary: "感染症、ワクチン、糖尿病、がん領域などを中心に医薬品を提供しています。",
        focusAreas: ["感染症", "ワクチン", "糖尿病", "がん"],
        representativeMedicines: ["ジャヌビア", "キイトルーダ", "シングレア", "ニューモバックス"]
    ),
    .init(
        id: "boehringer",
        name: "日本ベーリンガーインゲルハイム",
        kana: "にほんべーりんがーいんげるはいむ",
        urlString: "https://www.boehringer-ingelheim.com/jp/",
        summary: "呼吸器、循環器、糖尿病などの領域で医薬品を展開しています。",
        focusAreas: ["呼吸器", "循環器", "糖尿病"],
        representativeMedicines: ["ジャディアンス", "ミカルディス", "スピリーバ", "プラザキサ"]
    ),
    .init(
        id: "astrazeneca",
        name: "アストラゼネカ",
        kana: "あすとらぜねか",
        urlString: "https://www.astrazeneca.co.jp/",
        summary: "がん、循環器・腎・代謝、呼吸器・免疫領域などを重点領域としています。",
        focusAreas: ["がん", "循環器", "腎", "呼吸器"],
        representativeMedicines: ["フォシーガ", "ネキシウム", "シムビコート", "タグリッソ"]
    ),
    .init(
        id: "gsk",
        name: "グラクソ・スミスクライン",
        kana: "ぐらくそすみすくらいん",
        urlString: "https://jp.gsk.com/",
        summary: "呼吸器、ワクチン、感染症、免疫炎症などの領域で医薬品を扱います。",
        focusAreas: ["呼吸器", "ワクチン", "感染症", "免疫"],
        representativeMedicines: ["レルベア", "アラミスト", "ゾビラックス", "シングリックス"]
    ),
    .init(
        id: "bayer",
        name: "バイエル薬品",
        kana: "ばいえるやくひん",
        urlString: "https://www.pharma.bayer.jp/",
        summary: "循環器、眼科、女性医療、がん領域などの医薬品を扱います。",
        focusAreas: ["循環器", "眼科", "女性医療", "がん"],
        representativeMedicines: ["イグザレルト", "アイリーア", "ヤーズ", "ネクサバール"]
    ),
    .init(
        id: "sanofi",
        name: "サノフィ",
        kana: "さのふぃ",
        urlString: "https://www.sanofi.co.jp/",
        summary: "糖尿病、免疫、希少疾患、ワクチンなどの領域で医薬品を展開しています。",
        focusAreas: ["糖尿病", "免疫", "希少疾患", "ワクチン"],
        representativeMedicines: ["ランタス", "デュピクセント", "プラビックス", "アレグラ"]
    ),
    .init(
        id: "eli-lilly",
        name: "日本イーライリリー",
        kana: "にほんいーらいりりー",
        urlString: "https://www.lilly.com/jp/",
        summary: "糖尿病、がん、免疫、神経精神領域などを中心に医薬品を扱います。",
        focusAreas: ["糖尿病", "がん", "免疫", "神経精神"],
        representativeMedicines: ["トルリシティ", "サインバルタ", "オルミエント", "ベージニオ"]
    ),
    .init(
        id: "roche",
        name: "ロシュ",
        kana: "ろしゅ",
        urlString: "https://www.roche.com/ja",
        summary: "がん、免疫、神経、診断薬領域などを中心にグローバルに展開しています。",
        focusAreas: ["がん", "免疫", "神経", "診断薬"],
        representativeMedicines: ["アバスチン", "ハーセプチン", "リツキサン", "テセントリク"]
    )
]

struct ManufacturerView: View {
    @StateObject private var repository = MedicineRepository.shared
    @State private var query = ""

    private var allManufacturers: [DrugManufacturer] {
        let staticIDs = Set(manufacturerDatabase.map(\.id))
        let supplemental = synthesizedManufacturers(from: repository.allMedicines)
            .filter { !staticIDs.contains($0.id) }
        return (manufacturerDatabase + supplemental).sorted { normalize($0.name) < normalize($1.name) }
    }

    private var filteredManufacturers: [DrugManufacturer] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return allManufacturers }
        return allManufacturers.filter { manufacturer in
            let target = normalize(
                ([manufacturer.name, manufacturer.kana, manufacturer.summary] + manufacturer.focusAreas + manufacturer.representativeMedicines)
                    .joined(separator: " ")
            )
            return target.contains(normalizedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    searchField

                    ForEach(filteredManufacturers) { manufacturer in
                        NavigationLink {
                            ManufacturerDetailView(manufacturer: manufacturer)
                        } label: {
                            ManufacturerCard(manufacturer: manufacturer)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("薬品メーカー")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("メーカー名・薬品名で検索", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ManufacturerCard: View {
    let manufacturer: DrugManufacturer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(manufacturer.name)
                        .font(.headline)
                    Text(manufacturer.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
            }

            FlowLayout(spacing: 6) {
                ForEach(manufacturer.focusAreas.prefix(4), id: \.self) { area in
                    Text(area)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.appIndigo)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appIndigo.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct ManufacturerDetailView: View {
    let manufacturer: DrugManufacturer
    @StateObject private var repository = MedicineRepository.shared

    private var matchedMedicines: [Medicine] {
        repository.allMedicines
            .filter { medicine in
                matchesManufacturer(medicine.maker, manufacturer: manufacturer)
                    || medicine.pricing.brand.maker == manufacturer.name
                    || medicine.pricing.generics.contains(where: { matchesManufacturer($0.maker, manufacturer: manufacturer) })
            }
            .sorted { $0.brandName < $1.brandName }
    }

    private var localMedicineNames: Set<String> {
        Set(matchedMedicines.flatMap { [$0.brandName, $0.name, $0.genericName] }.map(normalize))
    }

    private var representativeOnlyNames: [String] {
        manufacturer.representativeMedicines.filter { !localMedicineNames.contains(normalize($0)) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SectionBox(title: "メーカー概要", accentColor: .appIndigo) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(manufacturer.summary)
                            .font(.subheadline)
                            .lineSpacing(5)

                        FlowLayout(spacing: 6) {
                            ForEach(manufacturer.focusAreas, id: \.self) { area in
                                Text(area)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.appIndigo)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(Color.appIndigo.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        if let url = manufacturer.url {
                            Link(destination: url) {
                                Label("メーカー公式サイトを開く", systemImage: "building.2.crop.circle")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }

                SectionBox(title: "このアプリで詳細を見られる薬", accentColor: .appBlue) {
                    if matchedMedicines.isEmpty {
                        Text("現在の薬品データ内には、このメーカー名で照合できる薬がまだありません。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(matchedMedicines) { medicine in
                                NavigationLink {
                                    MedicineDetailView(medicine: medicine)
                                } label: {
                                    MedicineMiniRow(medicine: medicine)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                SectionBox(title: "代表的な薬品", accentColor: .appGreen) {
                    FlowLayout(spacing: 6) {
                        ForEach(manufacturer.representativeMedicines, id: \.self) { medicineName in
                            Text(medicineName)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.appGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.appGreen.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                        }
                    }

                    if !representativeOnlyNames.isEmpty {
                        Text("緑の一覧には、参考として主要製品名も含めています。アプリ内データにある薬は上の一覧から詳細を開けます。")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(manufacturer.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MedicineMiniRow: View {
    let medicine: Medicine

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(medicine.brandName)
                    .font(.subheadline.weight(.semibold))
                Text(medicine.genericName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(medicine.category)
                    .font(.caption2)
                    .foregroundColor(.appBlue)
            }
            Spacer()
            RxBadge(rx: medicine.rx)
        }
        .padding(12)
        .background(Color.appBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private func matchesManufacturer(_ value: String, manufacturer: DrugManufacturer) -> Bool {
    let normalizedValue = normalize(value)
    let normalizedName = normalize(manufacturer.name)
    guard !normalizedValue.isEmpty, !normalizedName.isEmpty else { return false }
    return normalizedValue == normalizedName
        || normalizedValue.contains(normalizedName)
        || normalizedName.contains(normalizedValue)
}

private func normalize(_ text: String) -> String {
    text
        .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
        .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
        .lowercased()
}

private func synthesizedManufacturers(from medicines: [Medicine]) -> [DrugManufacturer] {
    var medicinesByMaker: [String: Set<String>] = [:]
    var genericMakerNames: Set<String> = []

    for medicine in medicines {
        let allPairs = [(medicine.maker, medicine.brandName)]
            + medicine.pricing.generics.map { ($0.maker, $0.name) }

        for (maker, productName) in allPairs {
            let trimmedMaker = maker.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedProduct = productName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedMaker.isEmpty else { continue }

            medicinesByMaker[trimmedMaker, default: []].insert(trimmedProduct)
            if allPairs.dropFirst().contains(where: { $0.0 == maker && !$0.1.isEmpty }) || medicine.pricing.generics.contains(where: { $0.maker == maker }) {
                genericMakerNames.insert(trimmedMaker)
            }
        }
    }

    return genericMakerNames.compactMap { maker in
        let representativeMedicines = Array(medicinesByMaker[maker] ?? [])
            .filter { !$0.isEmpty }
            .sorted()
        guard !representativeMedicines.isEmpty else { return nil }

        return DrugManufacturer(
            id: "generic-\(normalize(maker))",
            name: maker,
            kana: maker,
            urlString: Medicine.manufacturerURL(for: maker),
            summary: "ジェネリック医薬品の供給実績があるメーカーです。アプリ内データに含まれる後発品・同成分薬から自動で一覧化しています。",
            focusAreas: ["ジェネリック", "後発品", "医療用医薬品"],
            representativeMedicines: Array(representativeMedicines.prefix(8))
        )
    }
}
