import Foundation

extension Medicine {
    static func manufacturerURL(for maker: String) -> String {
        let officialURLs: [String: String] = [
            "第一三共": "https://www.daiichisankyo.co.jp/",
            "ヴィアトリス製薬": "https://www.viatris.co.jp/ja-jp",
            "UCBジャパン": "https://www.ucb.com/jp",
            "太陽ファルマ": "https://www.taiyo-pharma.co.jp/ja/",
            "あゆみ製薬": "https://www.ayumi-pharma.com/",
            "アステラス製薬": "https://www.astellas.com/jp/",
            "日本ベーリンガーインゲルハイム": "https://www.boehringer-ingelheim.com/jp",
            "日本新薬": "https://www.nippon-shinyaku.co.jp/",
            "ノバルティスファーマ": "https://www.novartis.com/jp-ja/",
            "バイエル薬品": "https://www.bayer.com/ja/jp/",
            "武田薬品工業": "https://www.takeda.com/ja-jp/",
            "塩野義製薬": "https://www.shionogi.com/jp/ja/",
            "MSD": "https://www.msd.co.jp/",
            "田辺三菱製薬": "https://www.mt-pharma.co.jp/",
            "協和キリン": "https://www.kyowakirin.co.jp/",
            "ファイザー": "https://www.pfizer.co.jp/",
            "サノフィ": "https://www.sanofi.co.jp/ja/",
            "興和": "https://www.kowa.co.jp/",
            "持田製薬": "https://www.mochida.co.jp/",
            "エーザイ": "https://www.eisai.co.jp/",
            "ブリストル・マイヤーズ スクイブ": "https://www.bms.com/jp",
            "住友ファーマ": "https://www.sumitomo-pharma.co.jp/",
            "大正製薬": "https://www.taisho.co.jp/",
            "中外製薬": "https://www.chugai-pharm.co.jp/",
            "LTLファーマ": "https://www.ltl-pharma.com/",
            "三和化学研究所": "https://www.skk-net.com/",
            "ビオフェルミン製薬": "https://www.biofermin.co.jp/",
            "ミヤリサン製薬": "https://www.miyarisan.com/",
            "杏林製薬": "https://www.kyorin-pharm.co.jp/",
            "Meiji Seika ファルマ": "https://www.meiji-seika-pharma.co.jp/",
            "グラクソ・スミスクライン": "https://jp.gsk.com/ja-jp/",
            "帝人ファーマ": "https://www.teijin-pharma.co.jp/",
            "日本アルコン": "https://www.alcon.com/ja-jp/",
            "参天製薬": "https://www.santen.com/ja/",
            "マルホ": "https://www.maruho.co.jp/",
            "ツムラ": "https://www.tsumura.co.jp/",
            "旭化成ファーマ": "https://www.asahikasei-pharma.co.jp/",
            "あすか製薬": "https://www.aska-pharma.co.jp/",
            "鳥居薬品": "https://www.torii.co.jp/",
            "小野薬品工業": "https://www.ono-pharma.com/ja/",
            "日本イーライリリー": "https://www.lilly.com/jp",
            "大塚製薬": "https://www.otsuka.co.jp/",
            "ヤンセンファーマ": "https://www.janssen.com/japan/",
            "沢井製薬": "https://www.sawai.co.jp/",
            "東和薬品": "https://www.towayakuhin.co.jp/",
            "日医工": "https://www.nichiiko.co.jp/",
            "ニプロ": "https://www.nipro.co.jp/",
            "日本ジェネリック": "https://www.nihon-generic.co.jp/",
            "エイワイファーマ": "https://www.yoshindo.jp/ay/",
            "陽進堂": "https://www.yoshindo.jp/"
        ]

        if let official = officialURLs[maker] {
            return official
        }

        let encoded = "\(maker) 会社概要 医薬品".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? maker
        return "https://www.google.com/search?q=\(encoded)"
    }

    /// 追加DB用ライト初期化（全フィールドを埋めるが詳細はシンプル化）
    static func lite(
        id: Int,
        name: String, kana: String,
        genericName: String, brandName: String,
        category: String, maker: String,
        tags: [String], rx: Bool,
        makerURLString: String? = nil,
        photoURLString: String? = nil,
        dosageForm: String? = nil,
        imprintCodes: [String] = [],
        brandPrice: Double,
        brandPriceName: String? = nil,
        generics: [(name: String, price: Double, maker: String)] = [],
        unit: String = "錠",
        mechanism: String,
        actionSummary: String = "",
        indications: [String],
        dosage: String,
        dosageNotes: [String] = [],
        contraindications: [String] = ["本剤の成分に対し過敏症の既往歴のある患者"],
        adverseEffects: [(name: String, freq: String, detail: String)] = [],
        tmax: String = "1〜2時間", halfLife: String = "4〜8時間",
        proteinBinding: String = "約90%", metabolism: String = "肝臓（CYP3A4）", excretion: String = "尿・糞便",
        monitoring: [String] = [],
        pregnancyCategory: String = "有益性投与",
        whatIsIt: String,
        howToTake: String,
        sideEffects: [(icon: String, name: String, detail: String)] = [],
        dailyLife: [String] = [],
        interactionWarning: String,
        qa: [(q: String, a: String)] = []
    ) -> Medicine {
        Medicine(
            id: id, name: name, kana: kana,
            genericName: genericName, brandName: brandName,
            category: category, maker: maker, makerURLString: makerURLString ?? manufacturerURL(for: maker), packageInsertURLString: nil, photoURLString: photoURLString, dosageForm: dosageForm, imprintCodes: imprintCodes, tags: tags, rx: rx,
            pricing: Pricing(
                brand: .init(name: brandPriceName ?? "\(brandName) \(unit)", price: brandPrice, maker: maker),
                generics: generics.map { .init(name: $0.name, price: $0.price, maker: $0.maker) },
                unit: unit,
                source: "しろぼんねっと・日経メディカル（2024年度薬価）",
                patientBurden30: "薬価×日用量×30日×0.3（3割負担）"
            ),
            interactions: [],
            pro: ProInfo(
                mechanism: mechanism,
                actionSummary: actionSummary,
                indications: indications,
                dosage: dosage,
                dosageNotes: dosageNotes,
                contraindications: contraindications,
                adverseEffects: adverseEffects.map { AdverseEffect(name: $0.name, frequency: $0.freq, detail: $0.detail) },
                pk: PK(tmax: tmax, halfLife: halfLife, proteinBinding: proteinBinding, metabolism: metabolism, excretion: excretion),
                monitoring: monitoring,
                pregnancyCategory: pregnancyCategory
            ),
            general: GeneralInfo(
                whatIsIt: whatIsIt,
                howToTake: howToTake,
                sideEffects: sideEffects.map { SideEffect(icon: $0.icon, name: $0.name, detail: $0.detail) },
                dailyLife: dailyLife,
                interactionWarning: interactionWarning,
                qa: qa.map { QAItem(q: $0.q, a: $0.a) }
            )
        )
    }
}
