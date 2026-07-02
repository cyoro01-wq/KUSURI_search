import Foundation

// MARK: - Model
struct Medicine: Identifiable, Codable {
    let id: Int
    let name: String
    let kana: String
    let genericName: String
    let brandName: String
    let category: String
    let maker: String
    let makerURLString: String?
    let packageInsertURLString: String?
    let photoURLString: String?
    let dosageForm: String?
    let imprintCodes: [String]
    let tags: [String]
    /// ネット上で取り上げられている話題・備考（参考情報）
    let webTopics: [String]
    let rx: Bool
    let pricing: Pricing
    let interactions: [Interaction]
    let pro: ProInfo
    let general: GeneralInfo

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case kana
        case genericName
        case brandName
        case category
        case maker
        case makerURLString
        case packageInsertURLString
        case photoURLString
        case dosageForm
        case imprintCodes
        case tags
        case webTopics
        case rx
        case pricing
        case interactions
        case pro
        case general
    }

    init(
        id: Int,
        name: String,
        kana: String,
        genericName: String,
        brandName: String,
        category: String,
        maker: String,
        makerURLString: String? = nil,
        packageInsertURLString: String? = nil,
        photoURLString: String? = nil,
        dosageForm: String? = nil,
        imprintCodes: [String] = [],
        tags: [String],
        webTopics: [String] = [],
        rx: Bool,
        pricing: Pricing,
        interactions: [Interaction],
        pro: ProInfo,
        general: GeneralInfo
    ) {
        self.id = id
        self.name = name
        self.kana = kana
        self.genericName = genericName
        self.brandName = brandName
        self.category = category
        self.maker = maker
        self.makerURLString = makerURLString
        self.packageInsertURLString = packageInsertURLString
        self.photoURLString = photoURLString
        self.dosageForm = dosageForm
        self.imprintCodes = imprintCodes
        self.tags = tags
        self.webTopics = webTopics
        self.rx = rx
        self.pricing = pricing
        self.interactions = interactions
        self.pro = pro
        self.general = general
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        kana = try container.decode(String.self, forKey: .kana)
        genericName = try container.decode(String.self, forKey: .genericName)
        brandName = try container.decode(String.self, forKey: .brandName)
        category = try container.decode(String.self, forKey: .category)
        maker = try container.decode(String.self, forKey: .maker)
        makerURLString = try container.decodeIfPresent(String.self, forKey: .makerURLString)
        packageInsertURLString = try container.decodeIfPresent(String.self, forKey: .packageInsertURLString)
        photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURLString)
        dosageForm = try container.decodeIfPresent(String.self, forKey: .dosageForm)
        imprintCodes = try container.decodeIfPresent([String].self, forKey: .imprintCodes) ?? []
        tags = try container.decode([String].self, forKey: .tags)
        webTopics = try container.decodeIfPresent([String].self, forKey: .webTopics) ?? []
        rx = try container.decode(Bool.self, forKey: .rx)
        pricing = try container.decode(Pricing.self, forKey: .pricing)
        interactions = try container.decode([Interaction].self, forKey: .interactions)
        pro = try container.decode(ProInfo.self, forKey: .pro)
        general = try container.decode(GeneralInfo.self, forKey: .general)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kana, forKey: .kana)
        try container.encode(genericName, forKey: .genericName)
        try container.encode(brandName, forKey: .brandName)
        try container.encode(category, forKey: .category)
        try container.encode(maker, forKey: .maker)
        try container.encodeIfPresent(makerURLString, forKey: .makerURLString)
        try container.encodeIfPresent(packageInsertURLString, forKey: .packageInsertURLString)
        try container.encodeIfPresent(photoURLString, forKey: .photoURLString)
        try container.encodeIfPresent(dosageForm, forKey: .dosageForm)
        try container.encode(imprintCodes, forKey: .imprintCodes)
        try container.encode(tags, forKey: .tags)
        try container.encode(webTopics, forKey: .webTopics)
        try container.encode(rx, forKey: .rx)
        try container.encode(pricing, forKey: .pricing)
        try container.encode(interactions, forKey: .interactions)
        try container.encode(pro, forKey: .pro)
        try container.encode(general, forKey: .general)
    }

    var makerURL: URL? {
        URL(string: makerURLString ?? Medicine.manufacturerURL(for: maker))
    }

    var packageInsertURL: URL? {
        guard let packageInsertURLString else { return nil }
        return URL(string: packageInsertURLString)
    }

    var photoURL: URL? {
        guard let photoURLString else { return nil }
        if let url = URL(string: photoURLString),
           url.host == "www.rad-ar.or.jp",
           url.path.hasPrefix("/kusuri_img/"),
           let fixedURL = URL(string: "https://www.rad-ar.or.jp/siori\(url.path)") {
            return fixedURL
        }
        return URL(string: photoURLString)
    }

    struct Pricing: Codable {
        let brand: PriceItem
        let generics: [PriceItem]
        let unit: String
        let source: String
        let patientBurden30: String
        var note: String? = nil
        struct PriceItem: Codable { let name: String; let price: Double; let maker: String }
    }
    struct Interaction: Identifiable, Codable {
        let id = UUID()
        let drug: String; let severity: String; let mechanism: String; let action: String

        enum CodingKeys: String, CodingKey {
            case drug, severity, mechanism, action
        }
    }
    struct AdverseEffect: Identifiable, Codable {
        let id = UUID()
        let name: String; let frequency: String; let detail: String

        enum CodingKeys: String, CodingKey {
            case name, frequency, detail
        }
    }
    struct PK: Codable {
        let tmax: String; let halfLife: String; let proteinBinding: String
        let metabolism: String; let excretion: String
    }
    struct ProInfo: Codable {
        struct DocumentSection: Identifiable, Codable {
            let id = UUID()
            let title: String
            let body: String

            enum CodingKeys: String, CodingKey {
                case title, body
            }
        }

        let mechanism: String; let actionSummary: String; let indications: [String]; let dosage: String
        let dosageNotes: [String]
        let contraindications: [String]; let adverseEffects: [AdverseEffect]
        let pk: PK; let monitoring: [String]; let pregnancyCategory: String
        let documentSections: [DocumentSection]

        init(
            mechanism: String,
            actionSummary: String = "",
            indications: [String],
            dosage: String,
            dosageNotes: [String] = [],
            contraindications: [String],
            adverseEffects: [AdverseEffect],
            pk: PK,
            monitoring: [String],
            pregnancyCategory: String,
            documentSections: [DocumentSection] = []
        ) {
            self.mechanism = mechanism
            self.actionSummary = actionSummary
            self.indications = indications
            self.dosage = dosage
            self.dosageNotes = dosageNotes
            self.contraindications = contraindications
            self.adverseEffects = adverseEffects
            self.pk = pk
            self.monitoring = monitoring
            self.pregnancyCategory = pregnancyCategory
            self.documentSections = documentSections
        }
    }
    struct SideEffect: Identifiable, Codable {
        let id = UUID()
        let icon: String; let name: String; let detail: String

        enum CodingKeys: String, CodingKey {
            case icon, name, detail
        }
    }
    struct QAItem: Identifiable, Codable {
        let id = UUID()
        let q: String; let a: String

        enum CodingKeys: String, CodingKey {
            case q, a
        }
    }
    struct GeneralInfo: Codable {
        let whatIsIt: String; let howToTake: String; let sideEffects: [SideEffect]
        let dailyLife: [String]; let interactionWarning: String; let qa: [QAItem]
    }
}

// MARK: - Base Data（詳細データ付き4薬剤）
let baseMedicines: [Medicine] = [
    Medicine(
        id: 1, name: "ロキソプロフェンNa錠60mg", kana: "ろきそぷろふぇんな",
        genericName: "ロキソプロフェンナトリウム水和物", brandName: "ロキソニン",
        category: "解熱鎮痛消炎剤", maker: "第一三共",
        tags: ["鎮痛", "解熱", "消炎", "NSAIDs"],
        webTopics: [
            "市販薬「ロキソニンS」と主成分が同じことが比較記事でよく取り上げられる",
            "空腹時に飲むと胃を痛めやすいという注意喚起がSNSで繰り返し話題になる",
            "貼り薬の「ロキソニンテープ」も知名度が高く、飲み薬との使い分けが解説されることが多い",
            "頭痛薬・生理痛薬としてイブ（イブプロフェン）やカロナールとの違いが頻繁に検索されている"
        ], rx: true,
        pricing: Medicine.Pricing(
            brand: .init(name: "ロキソニン錠60mg", price: 10.10, maker: "第一三共"),
            generics: [
                .init(name: "ロキソプロフェンNa錠60mg「トーワ」", price: 9.80, maker: "東和薬品"),
                .init(name: "ロキソプロフェンNa錠60mg「サワイ」", price: 9.80, maker: "沢井製薬")
            ],
            unit: "錠", source: "日経メディカル処方薬事典・しろぼんねっと（2024年度薬価）",
            patientBurden30: "先発品（3錠/日×30日）：約273円（3割負担）"
        ),
        interactions: [
            .init(drug: "ワルファリン", severity: "重大",
                  mechanism: "血漿蛋白結合競合によりワルファリン遊離型が増加し、抗凝固作用が増強される",
                  action: "PT-INRを頻回にモニタリング。可能であれば併用回避。"),
            .init(drug: "メトトレキサート（MTX）", severity: "重大",
                  mechanism: "腎尿細管でのMTX排泄を阻害し血中濃度が上昇。骨髄抑制・腎毒性リスクが著しく増大",
                  action: "原則併用禁忌。MTX濃度・腎機能を密にモニタリング。"),
            .init(drug: "ACE阻害薬・ARB", severity: "中等度",
                  mechanism: "PG合成抑制により腎血流が低下し降圧効果が減弱",
                  action: "血圧・腎機能のモニタリング強化。"),
            .init(drug: "利尿薬（フロセミドなど）", severity: "中等度",
                  mechanism: "腎血流量低下により利尿効果が減弱し急性腎障害リスクが増大",
                  action: "腎機能（血清Cr）のモニタリング。"),
            .init(drug: "リチウム", severity: "中等度",
                  mechanism: "腎でのリチウム再吸収が増加しリチウム毒性リスクが上昇",
                  action: "リチウム濃度の定期測定。")
        ],
        pro: Medicine.ProInfo(
            mechanism: "シクロオキシゲナーゼ（COX-1/COX-2）を非選択的に阻害し、アラキドン酸カスケードにおけるプロスタグランジン（PG）・トロンボキサン（TXA₂）の生合成を抑制する。プロドラッグ型NSAIDsであり、消化管壁での加水分解により活性体に変換される。胃粘膜への直接障害が比較的少ない。",
            indications: ["関節リウマチ", "変形性関節症", "腰痛症", "肩関節周囲炎", "頸肩腕症候群", "歯痛", "術後・外傷後の鎮痛・消炎", "急性上気道炎の解熱・鎮痛"],
            dosage: "通常、成人に1回60mgを1日3回食後経口投与。頓用の場合は1回60〜120mg。最大用量180mg/日。",
            contraindications: ["消化性潰瘍", "重篤な腎障害", "重篤な肝障害", "重篤な心機能不全", "アスピリン喘息（NSAIDs過敏症）", "妊娠末期（28週以降）"],
            adverseEffects: [
                .init(name: "消化管障害", frequency: "1〜5%", detail: "胃痛・悪心・消化性潰瘍。食後服用で軽減。"),
                .init(name: "腎機能障害", frequency: "0.1〜1%", detail: "PG阻害による腎血流低下。高齢者・脱水時に注意。"),
                .init(name: "肝機能異常", frequency: "0.1〜1%", detail: "AST/ALT上昇。定期的な肝機能検査を推奨。"),
                .init(name: "過敏症・蕁麻疹", frequency: "<0.1%", detail: "アスピリン喘息患者には禁忌。"),
                .init(name: "浮腫・高血圧増悪", frequency: "0.1〜1%", detail: "Na貯留作用。心不全・高血圧患者に注意。")
            ],
            pk: .init(tmax: "0.5〜1時間（活性体）", halfLife: "約1.3時間（活性体）",
                      proteinBinding: "約97%",
                      metabolism: "肝カルボニル還元酵素によりプロドラッグ→活性体変換。グルクロン酸抱合で不活化。",
                      excretion: "尿中（約50%）、糞便中（約25%）"),
            monitoring: ["消化器症状（胃痛・黒色便）", "腎機能：血清Cr・BUN（長期使用時）", "肝機能：AST/ALT（長期使用時）", "ワルファリン併用時：PT-INR"],
            pregnancyCategory: "妊娠28週以降は投与禁忌。妊娠初期・中期も治療上の有益性が危険性を上回る場合のみ。"
        ),
        general: Medicine.GeneralInfo(
            whatIsIt: "ロキソプロフェンは「NSAIDs（非ステロイド性抗炎症薬）」の一種で、痛みや炎症、発熱を和らげます。風邪の発熱、歯痛、頭痛、生理痛、腰痛など幅広く使われています。市販薬「ロキソニンS」と同じ成分です。",
            howToTake: "必ず食後にコップ1杯の水またはぬるま湯で飲んでください。1回1錠（60mg）を1日3回まで。痛みや熱のときだけ飲む「頓服」としても使えます。",
            sideEffects: [
                .init(icon: "🤢", name: "胃の不快感・痛み", detail: "最も多い副作用です。必ず食後に飲むことで軽減できます。"),
                .init(icon: "💧", name: "むくみ（浮腫）", detail: "足首などにむくみが出ることがあります。続く場合は相談を。"),
                .init(icon: "🌡️", name: "発疹・かゆみ", detail: "皮膚に症状が出たら服用を中止し、すぐに医師へ。")
            ],
            dailyLife: ["必ず食後に服用する", "アルコールとの同時摂取は避ける", "市販の頭痛薬など他のNSAIDsとの重複服用は不可", "妊娠中・授乳中は必ず医師に相談", "長期連用は避け、症状が改善したら中止を"],
            interactionWarning: "血液をさらさらにする薬（ワルファリンなど）を服用中の方は必ずお申し出ください。出血のリスクが高まる可能性があります。",
            qa: [
                .init(q: "飲み忘れたら？", a: "気づいた時点で服用を。次の服用時間が近い場合は1回分を飛ばしてください。2回分を一度に飲まないこと。"),
                .init(q: "胃が痛くなったら？", a: "服用を中止し、薬剤師・医師に相談してください。"),
                .init(q: "市販のロキソニンSとの違いは？", a: "主成分（ロキソプロフェン60mg）は同じです。市販品は薬局で購入でき、処方薬は医師の診断に基づいて処方されます。")
            ]
        )
    ),

    Medicine(
        id: 2, name: "アムロジピンベシル酸塩錠5mg", kana: "あむろじぴん",
        genericName: "アムロジピンベシル酸塩", brandName: "ノルバスク",
        category: "カルシウム拮抗薬", maker: "ヴィアトリス製薬",
        tags: ["降圧薬", "狭心症", "CCB", "Ca拮抗薬"],
        webTopics: [
            "グレープフルーツとの飲み合わせNGの代表例としてネット記事・SNSで頻繁に紹介される",
            "日本で最も処方されている降圧薬のひとつとして健康系メディアで取り上げられる",
            "ジェネリック（アムロジピン）の普及率が高く、薬代の節約例としてよく挙げられる",
            "「足のむくみ」が出やすい副作用として体験談・Q&Aサイトで話題になりやすい"
        ], rx: true,
        pricing: Medicine.Pricing(
            brand: .init(name: "ノルバスク錠5mg", price: 36.30, maker: "ヴィアトリス製薬"),
            generics: [
                .init(name: "アムロジピン錠5mg「JG」", price: 10.40, maker: "日本ジェネリック"),
                .init(name: "アムロジピン錠5mg「CH」", price: 10.40, maker: "長谷川製薬"),
                .init(name: "アムロジピン錠5mg「サワイ」", price: 10.40, maker: "沢井製薬")
            ],
            unit: "錠", source: "日経メディカル処方薬事典・しろぼんねっと（2024年度薬価）",
            patientBurden30: "先発品（1錠/日×30日）：約326円（3割負担）"
        ),
        interactions: [
            .init(drug: "グレープフルーツ（ジュース含む）", severity: "中等度",
                  mechanism: "グレープフルーツのフラノクマリン類がCYP3A4を阻害し、アムロジピン血中濃度が上昇",
                  action: "服用前後2時間はグレープフルーツを摂取しない。"),
            .init(drug: "シンバスタチン", severity: "中等度",
                  mechanism: "CYP3A4代謝競合によりシンバスタチン血中濃度が上昇し横紋筋融解症リスクが増大",
                  action: "シンバスタチンは20mg以下に制限（FDAガイドライン）。筋肉痛・尿の色に注意。"),
            .init(drug: "β遮断薬", severity: "軽度",
                  mechanism: "相加的な心抑制作用により徐脈・低血圧が生じる可能性",
                  action: "血圧・心拍数のモニタリング。"),
            .init(drug: "CYP3A4阻害薬（クラリスロマイシンなど）", severity: "中等度",
                  mechanism: "CYP3A4阻害によりアムロジピン代謝が低下し血中濃度上昇",
                  action: "血圧の定期的モニタリング。場合により減量を検討。")
        ],
        pro: Medicine.ProInfo(
            mechanism: "L型電位依存性カルシウムチャンネルを遮断し、血管平滑筋および心筋細胞へのCa²⁺流入を阻害する。末梢血管抵抗を低下させ降圧作用を示すと同時に冠動脈を拡張させ狭心症発作を予防する。半減期が約35時間と長く、1日1回投与で安定した血中濃度を維持できる。",
            indications: ["高血圧症", "狭心症（安定狭心症・異型狭心症）"],
            dosage: "高血圧：通常、成人に2.5〜5mgを1日1回経口投与。効果不十分な場合は10mgまで増量可。狭心症：5〜10mgを1日1回。",
            contraindications: ["ジヒドロピリジン系薬に過敏症の既往", "妊婦（動物実験で催奇形性）", "重篤な大動脈弁狭窄症"],
            adverseEffects: [
                .init(name: "浮腫（下腿・足首）", frequency: "5〜10%", detail: "最も多い副作用。末梢血管拡張によるもの。夕方に悪化しやすい。"),
                .init(name: "頭痛・顔面紅潮", frequency: "1〜5%", detail: "服薬開始初期に多い。通常は慣れとともに軽減。"),
                .init(name: "動悸", frequency: "1〜5%", detail: "反射性頻脈による。"),
                .init(name: "歯肉増殖", frequency: "<1%", detail: "長期服用者に発現。口腔清潔保持で予防。")
            ],
            pk: .init(tmax: "6〜12時間", halfLife: "約35時間（長時間作用型）",
                      proteinBinding: "約98%",
                      metabolism: "主にCYP3A4による肝代謝（非活性代謝物に変換）",
                      excretion: "尿中（約60%、主に代謝物として）"),
            monitoring: ["血圧・心拍数（特に投与開始時・増量時）", "下腿浮腫の有無", "スタチン系薬との併用時：CPK・筋肉痛"],
            pregnancyCategory: "妊娠中は投与しないことが望ましい。動物実験で催奇形性・胎児毒性が報告。"
        ),
        general: Medicine.GeneralInfo(
            whatIsIt: "アムロジピンは「カルシウム拮抗薬」と呼ばれる血圧を下げる薬です。血管を広げることで血圧を下げ、心臓への血の流れも改善します。高血圧や狭心症の治療に使われます。1日1回飲む薬で、長く効果が続きます。",
            howToTake: "1日1回、いつ飲んでも大丈夫です（食事に関係なく可）。毎日同じ時間帯に飲む習慣をつけることが大切です。急に飲むのをやめないでください。",
            sideEffects: [
                .init(icon: "🦵", name: "足のむくみ", detail: "最も多い副作用です。夕方に悪化しやすい。ひどい場合は医師へ。"),
                .init(icon: "🔴", name: "顔のほてり・頭痛", detail: "飲み始めの頃に多い症状です。通常は時間が経つと慣れてきます。"),
                .init(icon: "💓", name: "動悸", detail: "血管が広がることで起こることがあります。激しい場合は医師へ。")
            ],
            dailyLife: ["グレープフルーツ・グレープフルーツジュースは避ける（薬の効果が強まる）", "急に服用をやめない（血圧が急上昇する危険性）", "毎日同じ時間に飲む習慣を", "塩分の多い食事は降圧効果を妨げる", "立ち上がりはゆっくりと（立ちくらみ予防）"],
            interactionWarning: "グレープフルーツを食べると薬の効き目が強まりすぎる場合があります。服用前後2時間はグレープフルーツを避けてください。",
            qa: [
                .init(q: "飲み忘れたら？", a: "気づいた当日中は服用してください。翌日以降に気づいた場合は1回分を飛ばし、次回分から通常通り服用。"),
                .init(q: "足がむくんできたが？", a: "むくみは多くの患者さんに起こる副作用です。ひどい場合は医師に相談を。"),
                .init(q: "急に飲むのをやめてもいいか？", a: "絶対にやめないでください。急に中断すると血圧が急上昇し、心臓発作・脳卒中のリスクが高まります。")
            ]
        )
    ),

    Medicine(
        id: 3, name: "セチリジン塩酸塩錠10mg", kana: "せちりじん",
        genericName: "セチリジン塩酸塩", brandName: "ジルテック",
        category: "抗ヒスタミン薬", maker: "UCBジャパン",
        tags: ["抗アレルギー", "花粉症", "蕁麻疹", "H1拮抗薬"],
        webTopics: [
            "同成分の市販薬（ストナリニZ・コンタック鼻炎Zなど）が薬局で買えると紹介されることが多い",
            "改良型の「ザイザル（レボセチリジン）」との違いが花粉症シーズンによく検索される",
            "第2世代の中では効き目が強い一方、眠気も出やすいという比較記事が定番",
            "花粉が飛び始める前からの「初期療法」が効果的という情報が毎年話題になる"
        ], rx: false,
        pricing: Medicine.Pricing(
            brand: .init(name: "ジルテック錠10mg", price: 21.00, maker: "UCBジャパン"),
            generics: [
                .init(name: "セチリジン塩酸塩錠10mg「CH」", price: 10.40, maker: "長谷川製薬"),
                .init(name: "セチリジン塩酸塩錠10mg「YD」", price: 10.40, maker: "陽進堂"),
                .init(name: "セチリジン塩酸塩錠10mg「JG」", price: 10.40, maker: "日本ジェネリック")
            ],
            unit: "錠", source: "日経メディカル処方薬事典・しろぼんねっと（2024年度薬価）",
            patientBurden30: "先発品（1錠/日×30日）：約189円（3割負担）"
        ),
        interactions: [
            .init(drug: "アルコール", severity: "中等度",
                  mechanism: "相加的な中枢抑制作用により眠気・判断力低下が増強",
                  action: "服用中は飲酒を避ける。"),
            .init(drug: "ベンゾジアゼピン系・鎮静薬", severity: "中等度",
                  mechanism: "相加的な鎮静作用の増強",
                  action: "併用は可能だが過度の眠気に注意。用量調整を検討。"),
            .init(drug: "テオフィリン", severity: "注意",
                  mechanism: "テオフィリンがセチリジンのクリアランスをわずかに低下させる可能性",
                  action: "通常は問題ないが高用量テオフィリン使用時は注意。")
        ],
        pro: Medicine.ProInfo(
            mechanism: "末梢性選択的H₁受容体拮抗薬。ヒスタミンH₁受容体への選択的結合阻害により、ヒスタミン誘発性のかゆみ・血管拡張・血管透過性亢進を抑制する。第二世代抗ヒスタミン薬であり、血液脳関門の通過が少なく中枢性副作用（鎮静）が第一世代より軽減されている。",
            indications: ["アレルギー性鼻炎（花粉症含む）", "蕁麻疹", "皮膚疾患に伴うそう痒（湿疹・皮膚炎・アトピー性皮膚炎）"],
            dosage: "通常、成人に1回10mgを1日1回（就寝前）経口投与。腎機能低下患者（Ccr 11〜40mL/min）では5mg/日に減量を検討。",
            contraindications: ["本剤成分またはヒドロキシジンに過敏症の既往", "重篤な腎障害（Ccr<10mL/min）は使用禁忌"],
            adverseEffects: [
                .init(name: "眠気・傾眠", frequency: "10〜15%", detail: "第二世代だが一定程度発現。就寝前服用が推奨される理由。"),
                .init(name: "口腔乾燥", frequency: "1〜5%", detail: "抗コリン作用による。水分摂取で緩和。"),
                .init(name: "頭痛", frequency: "1〜5%", detail: "通常は軽度。"),
                .init(name: "肝機能異常", frequency: "<1%", detail: "AST/ALT上昇。")
            ],
            pk: .init(tmax: "1〜2時間", halfLife: "約10時間",
                      proteinBinding: "約93%",
                      metabolism: "肝代謝はわずか。主に未変化体で排泄（CYP関与少）",
                      excretion: "尿中（約70%、未変化体として）"),
            monitoring: ["眠気・傾眠（運転・機械操作に注意）", "腎機能（用量調整基準：Ccr<40mL/min→5mg）", "口腔乾燥・排尿障害（高齢男性）"],
            pregnancyCategory: "動物実験で催奇形性の報告なし。ただし十分なデータがないため有益性が危険性を上回る場合のみ使用。"
        ),
        general: Medicine.GeneralInfo(
            whatIsIt: "セチリジンは「第二世代抗ヒスタミン薬」と呼ばれるアレルギーの薬です。花粉症のくしゃみ・鼻水・目のかゆみ、蕁麻疹のかゆみなどに効果があります。古いアレルギー薬と比べて眠くなりにくいのが特徴です。",
            howToTake: "1日1回、就寝前に飲むのが一般的です。食事に関係なく飲めます。毎日続けて飲むことで効果が持続します（花粉症シーズン中は毎日服用）。",
            sideEffects: [
                .init(icon: "😴", name: "眠気", detail: "第二世代ですが眠気が出ることがあります。服用後の運転は注意。"),
                .init(icon: "👄", name: "口の乾き", detail: "水をこまめに飲むことで緩和できます。"),
                .init(icon: "🤕", name: "頭痛", detail: "通常は軽度で続かないことがほとんどです。")
            ],
            dailyLife: ["服用中の運転・機械操作は注意（眠気が出る場合）", "アルコールは眠気を強めるため避ける", "花粉症には症状が出る前から飲み始めると効果的", "腎臓に病気がある方は医師に必ず伝える"],
            interactionWarning: "お酒と一緒に飲むと眠気が強くなります。服用中は飲酒を控えましょう。他の眠くなる薬（睡眠薬など）も同様です。",
            qa: [
                .init(q: "いつから飲み始めればいい？", a: "花粉症の方は、花粉が飛び始める2週間前から飲み始めると効果的です。"),
                .init(q: "眠くなったら運転してもいい？", a: "眠気がある場合は絶対に運転しないでください。"),
                .init(q: "子供に使える？", a: "7歳以上は小児用剤（5mg）が使えますが、必ず小児科医に相談してください。")
            ]
        )
    ),

    Medicine(
        id: 4, name: "オメプラゾール錠20mg", kana: "おめぷらぞーる",
        genericName: "オメプラゾール", brandName: "オメプラール",
        category: "プロトンポンプ阻害薬（PPI）", maker: "太陽ファルマ",
        tags: ["胃潰瘍", "逆流性食道炎", "PPI", "胃酸抑制"],
        webTopics: [
            "PPIの長期服用リスク（骨折・低マグネシウム血症など）を扱う健康記事で頻繁に言及される",
            "新しいタイプの「タケキャブ（P-CAB）」との効き方の違いが比較記事でよく取り上げられる",
            "ピロリ菌除菌治療のセット薬の一つとして解説されることが多い",
            "後発品が先発品より高い「薬価逆転」の珍しい例として話題になった"
        ], rx: true,
        pricing: Medicine.Pricing(
            brand: .init(name: "オメプラール錠20mg", price: 33.60, maker: "太陽ファルマ"),
            generics: [
                .init(name: "オメプラゾール錠20mg「ケミファ」", price: 37.80, maker: "日本薬品工業"),
                .init(name: "オメプラゾール錠20mg「サワイ」", price: 37.80, maker: "沢井製薬")
            ],
            unit: "錠", source: "日経メディカル処方薬事典・しろぼんねっと（2024年度薬価）",
            patientBurden30: "先発品（1錠/日×30日）：約302円（3割負担）",
            note: "⚠️ 薬価逆転：後発品（¥37.80）が先発品（¥33.60）より高い特殊ケース（2024年度薬価改定）"
        ),
        interactions: [
            .init(drug: "クロピドグレル（プラビックス）", severity: "重大",
                  mechanism: "共通のCYP2C19を競合的に阻害し、クロピドグレルの活性代謝物生成が低下。抗血小板効果が著しく減弱し心血管イベントリスクが増大",
                  action: "原則として併用禁忌に準じた扱い。ラベプラゾール等への変更を検討。"),
            .init(drug: "アタザナビル（HIV薬）", severity: "禁忌",
                  mechanism: "胃酸分泌低下によりアタザナビルの溶解・吸収が著しく低下し、HIV抑制効果が失われる",
                  action: "禁忌。アタザナビル使用中は全てのPPIが禁忌。"),
            .init(drug: "ワルファリン", severity: "中等度",
                  mechanism: "CYP2C19・CYP2C9阻害によりワルファリン代謝が低下し抗凝固効果が増強",
                  action: "PT-INRのモニタリング強化。"),
            .init(drug: "鉄剤・カルシウム剤", severity: "注意",
                  mechanism: "胃酸低下による無機塩類の溶解・吸収低下",
                  action: "時間をずらして服用（食前や酸性飲料と）。")
        ],
        pro: Medicine.ProInfo(
            mechanism: "壁細胞のH⁺/K⁺-ATPase（プロトンポンプ）を不可逆的に阻害し、胃酸分泌を強力に抑制する。プロドラッグであり胃壁細胞の酸性環境でスルフェンアミド型活性体に変換され、プロトンポンプのシステイン残基と共有結合する。食前（食事30分前）服用により最大効果が得られる。",
            indications: ["胃潰瘍・十二指腸潰瘍", "逆流性食道炎（GERD）", "ゾリンジャー・エリソン症候群", "NSAIDs投与時の胃潰瘍予防", "H.pylori除菌療法（三剤療法）"],
            dosage: "胃潰瘍：1回20mgを1日1回（朝食前）、8週間。逆流性食道炎：1回20mgを1日1〜2回、8〜24週間。H.pylori除菌：20mgを1日2回＋抗菌薬2剤、7日間。",
            contraindications: ["本剤成分に過敏症の既往", "アタザナビル・リルピビリン投与中（吸収低下）"],
            adverseEffects: [
                .init(name: "下痢・軟便", frequency: "2〜5%", detail: "最も多い消化器症状。"),
                .init(name: "頭痛", frequency: "1〜3%", detail: "通常は軽度・一過性。"),
                .init(name: "低マグネシウム血症", frequency: "長期使用で増加", detail: "1年以上の長期使用で発現リスク増大。筋痙攣・不整脈の原因になりうる。"),
                .init(name: "骨密度低下", frequency: "長期使用", detail: "骨折リスクの増加が報告。特に高齢者・長期使用患者。")
            ],
            pk: .init(tmax: "1〜3.5時間", halfLife: "約0.5〜1時間（薬理効果は24時間持続）",
                      proteinBinding: "約95%",
                      metabolism: "主にCYP2C19およびCYP3A4による肝代謝（CYP2C19多型により効果に個人差あり）",
                      excretion: "尿中（約80%）"),
            monitoring: ["消化器症状（下痢・腹痛）", "低マグネシウム血症：血清Mg（長期使用時）", "ビタミンB12（長期使用時：吸収低下）", "骨密度（長期使用・高齢者）", "クロピドグレル併用時：心血管イベント"],
            pregnancyCategory: "動物実験で催奇形性の報告なし。ヒトでの十分なデータは限られるが必要な場合は使用可能とされる。"
        ),
        general: Medicine.GeneralInfo(
            whatIsIt: "オメプラゾールは「PPI（プロトンポンプ阻害薬）」と呼ばれる、胃酸を強力に抑える薬です。胃潰瘍、十二指腸潰瘍、逆流性食道炎（胃酸が食道に逆流して起こる）の治療に使われます。胸やけや胃痛を和らげます。",
            howToTake: "食前（食事の30分前）に飲むと最も効果的です。1日1回が基本です。錠剤はかまずに丸ごと飲んでください（コーティングが重要）。",
            sideEffects: [
                .init(icon: "💩", name: "下痢・軟便", detail: "最も多い副作用です。通常は軽度で継続使用で改善することも。"),
                .init(icon: "🤕", name: "頭痛", detail: "軽度なことがほとんど。続く場合は医師に相談を。"),
                .init(icon: "🦴", name: "長期使用での骨への影響", detail: "1年以上の長期服用で骨がもろくなる可能性があります。")
            ],
            dailyLife: ["食前（30分前）に飲むと最大効果", "錠剤をかまずに丸飲みする", "コーヒー・アルコール・辛い食べ物は控えめに", "寝るときは上半身を少し高めに（逆流性食道炎の予防）", "長期服用の場合は定期的に医師の診察を"],
            interactionWarning: "血液をさらさらにする薬（クロピドグレル）を服用中の方は必ずお申し出ください。この薬の効果が弱まる可能性があります。",
            qa: [
                .init(q: "食前に飲み忘れたら？", a: "気づいた時点で食前でなくても服用してください。次回からは食前を意識してください。"),
                .init(q: "症状が良くなったら飲むのをやめていい？", a: "医師が指定した期間は継続してください。自己判断で中止すると再発することがあります。"),
                .init(q: "後発品が先発品より高いのはなぜ？", a: "薬価改定のタイミングや市場の状況により、まれに後発品が先発品より高くなることがあります。これを「薬価逆転」と呼びます。")
            ]
        )
    )
]
