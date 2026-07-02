import Foundation

private struct MedicineSeed {
    let genericName: String
    let brandName: String
    let kana: String
    let category: String
    let maker: String
    let tags: [String]
    let rx: Bool
    let brandPrice: Double
}

private let additionalMedicineSeeds: [MedicineSeed] = [
    .init(genericName: "アセトアミノフェン", brandName: "カロナール", kana: "あせとあみのふぇん", category: "解熱鎮痛薬", maker: "あゆみ製薬", tags: ["解熱", "鎮痛", "発熱"], rx: true, brandPrice: 8.90),
    .init(genericName: "セレコキシブ", brandName: "セレコックス", kana: "せれこきしぶ", category: "解熱鎮痛消炎剤", maker: "アステラス製薬", tags: ["NSAIDs", "鎮痛", "関節痛"], rx: true, brandPrice: 16.20),
    .init(genericName: "メロキシカム", brandName: "モービック", kana: "めろきしかむ", category: "解熱鎮痛消炎剤", maker: "日本ベーリンガーインゲルハイム", tags: ["NSAIDs", "炎症", "疼痛"], rx: true, brandPrice: 21.40),
    .init(genericName: "トラマドール塩酸塩", brandName: "トラマール", kana: "とらまどーる", category: "鎮痛薬", maker: "日本新薬", tags: ["鎮痛", "慢性疼痛", "神経障害性疼痛"], rx: true, brandPrice: 29.50),
    .init(genericName: "プレガバリン", brandName: "リリカ", kana: "ぷれがばりん", category: "鎮痛補助薬", maker: "ヴィアトリス製薬", tags: ["しびれ", "神経痛", "疼痛"], rx: true, brandPrice: 41.20),
    .init(genericName: "ジクロフェナクナトリウム", brandName: "ボルタレン", kana: "じくろふぇなく", category: "解熱鎮痛消炎剤", maker: "ノバルティスファーマ", tags: ["NSAIDs", "関節痛", "炎症"], rx: true, brandPrice: 11.10),
    .init(genericName: "イブプロフェン", brandName: "ブルフェン", kana: "いぶぷろふぇん", category: "解熱鎮痛消炎剤", maker: "科研製薬", tags: ["NSAIDs", "頭痛", "発熱"], rx: false, brandPrice: 7.40),
    .init(genericName: "ナプロキセン", brandName: "ナイキサン", kana: "なぷろきせん", category: "解熱鎮痛消炎剤", maker: "第一三共", tags: ["NSAIDs", "鎮痛", "炎症"], rx: true, brandPrice: 12.60),
    .init(genericName: "アムロジピン口腔内崩壊錠", brandName: "アムロジンOD", kana: "あむろじんおーでぃー", category: "カルシウム拮抗薬", maker: "大日本住友製薬", tags: ["降圧", "高血圧", "狭心症"], rx: true, brandPrice: 18.50),
    .init(genericName: "ニフェジピン", brandName: "アダラート", kana: "にふぇじぴん", category: "カルシウム拮抗薬", maker: "バイエル薬品", tags: ["降圧", "狭心症", "血圧"], rx: true, brandPrice: 22.60),
    .init(genericName: "アジルサルタン", brandName: "アジルバ", kana: "あじるさるたん", category: "ARB", maker: "武田薬品工業", tags: ["降圧", "ARB", "高血圧"], rx: true, brandPrice: 83.10),
    .init(genericName: "テルミサルタン", brandName: "ミカルディス", kana: "てるみさるたん", category: "ARB", maker: "日本ベーリンガーインゲルハイム", tags: ["降圧", "ARB", "腎保護"], rx: true, brandPrice: 62.40),
    .init(genericName: "バルサルタン", brandName: "ディオバン", kana: "ばるさるたん", category: "ARB", maker: "ノバルティスファーマ", tags: ["降圧", "ARB", "心不全"], rx: true, brandPrice: 39.70),
    .init(genericName: "カンデサルタン シレキセチル", brandName: "ブロプレス", kana: "かんでさるたん", category: "ARB", maker: "武田薬品工業", tags: ["降圧", "ARB", "高血圧"], rx: true, brandPrice: 36.30),
    .init(genericName: "ロサルタンカリウム", brandName: "ニューロタン", kana: "ろさるたん", category: "ARB", maker: "オルガノン", tags: ["降圧", "ARB", "蛋白尿"], rx: true, brandPrice: 32.40),
    .init(genericName: "イルベサルタン", brandName: "イルベタン", kana: "いるべさるたん", category: "ARB", maker: "塩野義製薬", tags: ["降圧", "ARB", "腎症"], rx: true, brandPrice: 48.10),
    .init(genericName: "エナラプリルマレイン酸塩", brandName: "レニベース", kana: "えならぷりる", category: "ACE阻害薬", maker: "MSD", tags: ["降圧", "ACE阻害薬", "心不全"], rx: true, brandPrice: 21.80),
    .init(genericName: "イミダプリル塩酸塩", brandName: "タナトリル", kana: "いみだぷりる", category: "ACE阻害薬", maker: "田辺三菱製薬", tags: ["降圧", "ACE阻害薬", "高血圧"], rx: true, brandPrice: 29.20),
    .init(genericName: "ペリンドプリルエルブミン", brandName: "コバシル", kana: "ぺりんどぷりる", category: "ACE阻害薬", maker: "協和キリン", tags: ["降圧", "ACE阻害薬", "心血管"], rx: true, brandPrice: 34.80),
    .init(genericName: "ビソプロロールフマル酸塩", brandName: "メインテート", kana: "びそぷろろーる", category: "β遮断薬", maker: "田辺三菱製薬", tags: ["降圧", "頻脈", "心不全"], rx: true, brandPrice: 24.50),
    .init(genericName: "カルベジロール", brandName: "アーチスト", kana: "かるべじろーる", category: "β遮断薬", maker: "第一三共", tags: ["心不全", "高血圧", "β遮断薬"], rx: true, brandPrice: 17.30),
    .init(genericName: "プロプラノロール塩酸塩", brandName: "インデラル", kana: "ぷろぷらのろーる", category: "β遮断薬", maker: "太陽ファルマ", tags: ["頻脈", "片頭痛", "β遮断薬"], rx: true, brandPrice: 9.80),
    .init(genericName: "フロセミド", brandName: "ラシックス", kana: "ふろせみど", category: "利尿薬", maker: "サノフィ", tags: ["利尿", "むくみ", "心不全"], rx: true, brandPrice: 10.20),
    .init(genericName: "アゾセミド", brandName: "ダイアート", kana: "あぞせみど", category: "利尿薬", maker: "三和化学研究所", tags: ["利尿", "浮腫", "心不全"], rx: true, brandPrice: 39.00),
    .init(genericName: "スピロノラクトン", brandName: "アルダクトンA", kana: "すぴろのらくとん", category: "利尿薬", maker: "ファイザー", tags: ["利尿", "高アルドステロン", "心不全"], rx: true, brandPrice: 12.40),
    .init(genericName: "トルバプタン", brandName: "サムスカ", kana: "とるばぷたん", category: "利尿薬", maker: "大塚製薬", tags: ["利尿", "低Na血症", "心不全"], rx: true, brandPrice: 274.50),
    .init(genericName: "ロスバスタチンカルシウム", brandName: "クレストール", kana: "ろすばすたちん", category: "脂質異常症治療薬", maker: "アストラゼネカ", tags: ["スタチン", "コレステロール", "脂質"], rx: true, brandPrice: 54.80),
    .init(genericName: "アトルバスタチンカルシウム水和物", brandName: "リピトール", kana: "あとるばすたちん", category: "脂質異常症治療薬", maker: "ヴィアトリス製薬", tags: ["スタチン", "脂質", "LDL"], rx: true, brandPrice: 45.60),
    .init(genericName: "ピタバスタチンカルシウム", brandName: "リバロ", kana: "ぴたばすたちん", category: "脂質異常症治療薬", maker: "興和", tags: ["スタチン", "脂質", "高コレステロール"], rx: true, brandPrice: 41.30),
    .init(genericName: "エゼチミブ", brandName: "ゼチーア", kana: "えぜちみぶ", category: "脂質異常症治療薬", maker: "MSD", tags: ["脂質", "コレステロール", "吸収阻害"], rx: true, brandPrice: 88.20),
    .init(genericName: "ベザフィブラート", brandName: "ベザトールSR", kana: "べざふぃぶらーと", category: "脂質異常症治療薬", maker: "キッセイ薬品工業", tags: ["中性脂肪", "脂質", "フィブラート"], rx: true, brandPrice: 23.10),
    .init(genericName: "イコサペント酸エチル", brandName: "エパデール", kana: "いこさぺんとさんえちる", category: "脂質異常症治療薬", maker: "持田製薬", tags: ["EPA", "中性脂肪", "脂質"], rx: true, brandPrice: 28.20),
    .init(genericName: "ワルファリンカリウム", brandName: "ワーファリン", kana: "わるふぁりん", category: "抗凝固薬", maker: "エーザイ", tags: ["抗凝固", "血栓", "AF"], rx: true, brandPrice: 9.70),
    .init(genericName: "アピキサバン", brandName: "エリキュース", kana: "あぴきさばん", category: "抗凝固薬", maker: "ブリストル・マイヤーズ スクイブ", tags: ["DOAC", "AF", "血栓"], rx: true, brandPrice: 285.40),
    .init(genericName: "リバーロキサバン", brandName: "イグザレルト", kana: "りばーろきさばん", category: "抗凝固薬", maker: "バイエル薬品", tags: ["DOAC", "血栓", "AF"], rx: true, brandPrice: 285.40),
    .init(genericName: "エドキサバントシル酸塩水和物", brandName: "リクシアナ", kana: "えどきさばん", category: "抗凝固薬", maker: "第一三共", tags: ["DOAC", "血栓", "静脈血栓"], rx: true, brandPrice: 288.90),
    .init(genericName: "ダビガトランエテキシラートメタンスルホン酸塩", brandName: "プラザキサ", kana: "だびがとらん", category: "抗凝固薬", maker: "日本ベーリンガーインゲルハイム", tags: ["DOAC", "AF", "抗凝固"], rx: true, brandPrice: 270.20),
    .init(genericName: "クロピドグレル硫酸塩", brandName: "プラビックス", kana: "くろぴどぐれる", category: "抗血小板薬", maker: "サノフィ", tags: ["抗血小板", "脳梗塞", "PCI"], rx: true, brandPrice: 75.50),
    .init(genericName: "アスピリン腸溶錠", brandName: "バイアスピリン", kana: "あすぴりん", category: "抗血小板薬", maker: "バイエル薬品", tags: ["抗血小板", "心筋梗塞", "脳梗塞"], rx: true, brandPrice: 6.40),
    .init(genericName: "シロスタゾール", brandName: "プレタール", kana: "しろすたぞーる", category: "抗血小板薬", maker: "大塚製薬", tags: ["抗血小板", "末梢循環", "脳梗塞"], rx: true, brandPrice: 27.40),
    .init(genericName: "メトホルミン塩酸塩", brandName: "メトグルコ", kana: "めとほるみん", category: "糖尿病治療薬", maker: "住友ファーマ", tags: ["糖尿病", "血糖", "ビグアナイド"], rx: true, brandPrice: 10.10),
    .init(genericName: "シタグリプチンリン酸塩水和物", brandName: "ジャヌビア", kana: "したぐりぷちん", category: "糖尿病治療薬", maker: "MSD", tags: ["糖尿病", "DPP-4", "血糖"], rx: true, brandPrice: 149.30),
    .init(genericName: "リナグリプチン", brandName: "トラゼンタ", kana: "りなぐりぷちん", category: "糖尿病治療薬", maker: "日本ベーリンガーインゲルハイム", tags: ["糖尿病", "DPP-4", "血糖"], rx: true, brandPrice: 139.90),
    .init(genericName: "テネリグリプチン臭化水素酸塩水和物", brandName: "テネリア", kana: "てねりぐりぷちん", category: "糖尿病治療薬", maker: "第一三共", tags: ["糖尿病", "DPP-4", "血糖"], rx: true, brandPrice: 121.60),
    .init(genericName: "エンパグリフロジン", brandName: "ジャディアンス", kana: "えんぱぐりふろじん", category: "糖尿病治療薬", maker: "日本ベーリンガーインゲルハイム", tags: ["糖尿病", "SGLT2", "心不全"], rx: true, brandPrice: 210.40),
    .init(genericName: "ダパグリフロジンプロピレングリコール水和物", brandName: "フォシーガ", kana: "だぱぐりふろじん", category: "糖尿病治療薬", maker: "アストラゼネカ", tags: ["糖尿病", "SGLT2", "腎保護"], rx: true, brandPrice: 211.10),
    .init(genericName: "ルセオグリフロジン水和物", brandName: "ルセフィ", kana: "るせおぐりふろじん", category: "糖尿病治療薬", maker: "大正製薬", tags: ["糖尿病", "SGLT2", "血糖"], rx: true, brandPrice: 198.50),
    .init(genericName: "グリメピリド", brandName: "アマリール", kana: "ぐりめぴりど", category: "糖尿病治療薬", maker: "サノフィ", tags: ["糖尿病", "SU", "血糖"], rx: true, brandPrice: 11.30),
    .init(genericName: "グリクラジド", brandName: "グリミクロン", kana: "ぐりくらじど", category: "糖尿病治療薬", maker: "住友ファーマ", tags: ["糖尿病", "SU", "血糖"], rx: true, brandPrice: 10.80),
    .init(genericName: "ピオグリタゾン塩酸塩", brandName: "アクトス", kana: "ぴおぐりたぞん", category: "糖尿病治療薬", maker: "武田薬品工業", tags: ["糖尿病", "インスリン抵抗性", "血糖"], rx: true, brandPrice: 30.20),
    .init(genericName: "インスリン グラルギン", brandName: "ランタス", kana: "いんすりんぐらるぎん", category: "インスリン製剤", maker: "サノフィ", tags: ["糖尿病", "インスリン", "持効型"], rx: true, brandPrice: 312.00),
    .init(genericName: "インスリン リスプロ", brandName: "ヒューマログ", kana: "いんすりんりすぷろ", category: "インスリン製剤", maker: "日本イーライリリー", tags: ["糖尿病", "インスリン", "超速効"], rx: true, brandPrice: 286.10),
    .init(genericName: "ランソプラゾール", brandName: "タケプロン", kana: "らんそぷらぞーる", category: "プロトンポンプ阻害薬（PPI）", maker: "武田薬品工業", tags: ["PPI", "胃潰瘍", "逆流性食道炎"], rx: true, brandPrice: 53.10),
    .init(genericName: "ラベプラゾールナトリウム", brandName: "パリエット", kana: "らべぷらぞーる", category: "プロトンポンプ阻害薬（PPI）", maker: "エーザイ", tags: ["PPI", "胃酸抑制", "GERD"], rx: true, brandPrice: 60.40),
    .init(genericName: "エソメプラゾールマグネシウム水和物", brandName: "ネキシウム", kana: "えそめぷらぞーる", category: "プロトンポンプ阻害薬（PPI）", maker: "アストラゼネカ", tags: ["PPI", "胃酸抑制", "逆流"], rx: true, brandPrice: 88.60),
    .init(genericName: "ボノプラザンフマル酸塩", brandName: "タケキャブ", kana: "ぼのぷらざん", category: "P-CAB", maker: "武田薬品工業", tags: ["胃酸抑制", "逆流性食道炎", "除菌"], rx: true, brandPrice: 123.50),
    .init(genericName: "ファモチジン", brandName: "ガスター", kana: "ふぁもちじん", category: "H2受容体拮抗薬", maker: "LTLファーマ", tags: ["胃酸抑制", "胃痛", "H2ブロッカー"], rx: false, brandPrice: 10.20),
    .init(genericName: "モサプリドクエン酸塩水和物", brandName: "ガスモチン", kana: "もさぷりど", category: "消化管運動改善薬", maker: "住友ファーマ", tags: ["胃もたれ", "消化不良", "胃運動"], rx: true, brandPrice: 18.60),
    .init(genericName: "ドンペリドン", brandName: "ナウゼリン", kana: "どんぺりどん", category: "制吐薬", maker: "協和キリン", tags: ["吐き気", "嘔吐", "胃もたれ"], rx: true, brandPrice: 11.40),
    .init(genericName: "テプレノン", brandName: "セルベックス", kana: "てぷれのん", category: "胃粘膜保護薬", maker: "エーザイ", tags: ["胃痛", "胃炎", "胃粘膜"], rx: true, brandPrice: 16.10),
    .init(genericName: "酸化マグネシウム", brandName: "マグミット", kana: "さんかまぐねしうむ", category: "下剤", maker: "協和化学工業", tags: ["便秘", "下剤", "制酸"], rx: true, brandPrice: 6.20),
    .init(genericName: "センノシド", brandName: "プルゼニド", kana: "せんのしど", category: "下剤", maker: "サンファーマ", tags: ["便秘", "下剤", "刺激性"], rx: true, brandPrice: 6.70),
    .init(genericName: "ルビプロストン", brandName: "アミティーザ", kana: "るびぷろすとん", category: "下剤", maker: "ヴィアトリス製薬", tags: ["便秘", "慢性便秘", "腸管分泌"], rx: true, brandPrice: 91.30),
    .init(genericName: "ラクツロース", brandName: "モニラック", kana: "らくつろーす", category: "下剤", maker: "三和化学研究所", tags: ["便秘", "高アンモニア血症", "下剤"], rx: true, brandPrice: 34.20),
    .init(genericName: "ビフィズス菌製剤", brandName: "ビオフェルミンR", kana: "びふぃずすきん", category: "整腸剤", maker: "ビオフェルミン製薬", tags: ["整腸", "下痢", "腸内環境"], rx: true, brandPrice: 6.90),
    .init(genericName: "酪酸菌製剤", brandName: "ミヤBM", kana: "らくさんきん", category: "整腸剤", maker: "ミヤリサン製薬", tags: ["整腸", "抗菌薬併用", "下痢"], rx: true, brandPrice: 5.50),
    .init(genericName: "ポリカルボフィルカルシウム", brandName: "コロネル", kana: "ぽりかるぼふぃる", category: "整腸剤", maker: "アボットジャパン", tags: ["過敏性腸症候群", "便通", "整腸"], rx: true, brandPrice: 31.80),
    .init(genericName: "ロペラミド塩酸塩", brandName: "ロペミン", kana: "ろぺらみど", category: "止瀉薬", maker: "ヤンセンファーマ", tags: ["下痢", "整腸", "止瀉"], rx: true, brandPrice: 10.10),
    .init(genericName: "アモキシシリン水和物", brandName: "サワシリン", kana: "あもきししりん", category: "抗菌薬", maker: "アステラス製薬", tags: ["感染症", "ペニシリン", "抗菌"], rx: true, brandPrice: 12.00),
    .init(genericName: "セフカペン ピボキシル塩酸塩水和物", brandName: "フロモックス", kana: "せふかぺん", category: "抗菌薬", maker: "塩野義製薬", tags: ["感染症", "セフェム", "抗菌"], rx: true, brandPrice: 56.10),
    .init(genericName: "セフジトレン ピボキシル", brandName: "メイアクトMS", kana: "せふじとれん", category: "抗菌薬", maker: "Meiji Seika ファルマ", tags: ["感染症", "セフェム", "抗菌"], rx: true, brandPrice: 49.80),
    .init(genericName: "レボフロキサシン水和物", brandName: "クラビット", kana: "れぼふろきさしん", category: "抗菌薬", maker: "第一三共", tags: ["感染症", "ニューキノロン", "抗菌"], rx: true, brandPrice: 82.30),
    .init(genericName: "クラリスロマイシン", brandName: "クラリス", kana: "くらりすろまいしん", category: "抗菌薬", maker: "大正製薬", tags: ["感染症", "マクロライド", "抗菌"], rx: true, brandPrice: 24.60),
    .init(genericName: "アジスロマイシン水和物", brandName: "ジスロマック", kana: "あじすろまいしん", category: "抗菌薬", maker: "ファイザー", tags: ["感染症", "マクロライド", "抗菌"], rx: true, brandPrice: 126.40),
    .init(genericName: "ミノサイクリン塩酸塩", brandName: "ミノマイシン", kana: "みのさいくりん", category: "抗菌薬", maker: "ファイザー", tags: ["抗菌", "ニキビ", "テトラサイクリン"], rx: true, brandPrice: 25.40),
    .init(genericName: "メトロニダゾール", brandName: "フラジール", kana: "めとろにだぞーる", category: "抗菌薬", maker: "EAファーマ", tags: ["嫌気性菌", "感染症", "抗菌"], rx: true, brandPrice: 16.70),
    .init(genericName: "オセルタミビルリン酸塩", brandName: "タミフル", kana: "おせるたみびる", category: "抗ウイルス薬", maker: "中外製薬", tags: ["インフルエンザ", "抗ウイルス", "発熱"], rx: true, brandPrice: 311.80),
    .init(genericName: "バロキサビル マルボキシル", brandName: "ゾフルーザ", kana: "ばろきさびる", category: "抗ウイルス薬", maker: "塩野義製薬", tags: ["インフルエンザ", "抗ウイルス", "発熱"], rx: true, brandPrice: 489.20),
    .init(genericName: "アシクロビル", brandName: "ゾビラックス", kana: "あしくろびる", category: "抗ウイルス薬", maker: "グラクソ・スミスクライン", tags: ["ヘルペス", "抗ウイルス", "口唇ヘルペス"], rx: true, brandPrice: 31.20),
    .init(genericName: "バラシクロビル塩酸塩", brandName: "バルトレックス", kana: "ばらしくろびる", category: "抗ウイルス薬", maker: "グラクソ・スミスクライン", tags: ["帯状疱疹", "ヘルペス", "抗ウイルス"], rx: true, brandPrice: 161.00),
    .init(genericName: "セチリジン塩酸塩シロップ", brandName: "ジルテックシロップ", kana: "せちりじんしろっぷ", category: "抗ヒスタミン薬", maker: "UCBジャパン", tags: ["花粉症", "アレルギー", "小児"], rx: true, brandPrice: 20.10),
    .init(genericName: "ロラタジン", brandName: "クラリチン", kana: "ろらたじん", category: "抗ヒスタミン薬", maker: "バイエル薬品", tags: ["花粉症", "蕁麻疹", "眠気少"], rx: true, brandPrice: 44.10),
    .init(genericName: "フェキソフェナジン塩酸塩", brandName: "アレグラ", kana: "ふぇきそふぇなじん", category: "抗ヒスタミン薬", maker: "サノフィ", tags: ["花粉症", "アレルギー", "眠気少"], rx: false, brandPrice: 19.90),
    .init(genericName: "エピナスチン塩酸塩", brandName: "アレジオン", kana: "えぴなすちん", category: "抗ヒスタミン薬", maker: "日本ベーリンガーインゲルハイム", tags: ["花粉症", "アレルギー", "鼻炎"], rx: true, brandPrice: 46.20),
    .init(genericName: "オロパタジン塩酸塩", brandName: "アレロック", kana: "おろぱたじん", category: "抗ヒスタミン薬", maker: "協和キリン", tags: ["花粉症", "蕁麻疹", "かゆみ"], rx: true, brandPrice: 44.60),
    .init(genericName: "モンテルカストナトリウム", brandName: "キプレス", kana: "もんてるかすと", category: "抗喘息薬", maker: "杏林製薬", tags: ["喘息", "アレルギー", "鼻炎"], rx: true, brandPrice: 101.50),
    .init(genericName: "プランルカスト水和物", brandName: "オノン", kana: "ぷらんるかすと", category: "抗喘息薬", maker: "小野薬品工業", tags: ["喘息", "アレルギー", "ロイコトリエン"], rx: true, brandPrice: 68.30),
    .init(genericName: "サルブタモール硫酸塩", brandName: "サルタノール", kana: "さるぶたもーる", category: "気管支拡張薬", maker: "グラクソ・スミスクライン", tags: ["喘息", "発作", "吸入"], rx: true, brandPrice: 334.60),
    .init(genericName: "ブデソニド・ホルモテロールフマル酸塩水和物", brandName: "シムビコート", kana: "しむびこーと", category: "吸入配合剤", maker: "アストラゼネカ", tags: ["喘息", "吸入", "ICS/LABA"], rx: true, brandPrice: 204.80),
    .init(genericName: "フルチカゾンフランカルボン酸エステル・ビランテロールトリフェニル酢酸塩", brandName: "レルベア", kana: "れるべあ", category: "吸入配合剤", maker: "グラクソ・スミスクライン", tags: ["喘息", "COPD", "吸入"], rx: true, brandPrice: 217.30),
    .init(genericName: "アンブロキソール塩酸塩", brandName: "ムコソルバン", kana: "あんぶろきそーる", category: "去痰薬", maker: "帝人ファーマ", tags: ["咳", "たん", "去痰"], rx: true, brandPrice: 9.60),
    .init(genericName: "カルボシステイン", brandName: "ムコダイン", kana: "かるぼしすていん", category: "去痰薬", maker: "杏林製薬", tags: ["たん", "副鼻腔炎", "去痰"], rx: true, brandPrice: 10.80),
    .init(genericName: "デキストロメトルファン臭化水素酸塩水和物", brandName: "メジコン", kana: "できすとろめとるふぁん", category: "鎮咳薬", maker: "シオノギヘルスケア", tags: ["咳", "鎮咳", "風邪"], rx: false, brandPrice: 8.30),
    .init(genericName: "アルプラゾラム", brandName: "ソラナックス", kana: "あるぷらぞらむ", category: "抗不安薬", maker: "ヴィアトリス製薬", tags: ["不安", "パニック", "ベンゾ"], rx: true, brandPrice: 10.10),
    .init(genericName: "エチゾラム", brandName: "デパス", kana: "えちぞらむ", category: "抗不安薬", maker: "田辺三菱製薬", tags: ["不安", "緊張", "睡眠"], rx: true, brandPrice: 9.70),
    .init(genericName: "ロラゼパム", brandName: "ワイパックス", kana: "ろらぜぱむ", category: "抗不安薬", maker: "ファイザー", tags: ["不安", "緊張", "ベンゾ"], rx: true, brandPrice: 11.40),
    .init(genericName: "ゾルピデム酒石酸塩", brandName: "マイスリー", kana: "ぞるぴでむ", category: "睡眠薬", maker: "アステラス製薬", tags: ["不眠", "睡眠", "入眠"], rx: true, brandPrice: 24.10),
    .init(genericName: "エスゾピクロン", brandName: "ルネスタ", kana: "えすぞぴくろん", category: "睡眠薬", maker: "エーザイ", tags: ["不眠", "睡眠", "入眠"], rx: true, brandPrice: 41.70),
    .init(genericName: "スボレキサント", brandName: "ベルソムラ", kana: "すぼれきさんと", category: "睡眠薬", maker: "MSD", tags: ["不眠", "睡眠", "オレキシン"], rx: true, brandPrice: 89.10),
    .init(genericName: "レンボレキサント", brandName: "デエビゴ", kana: "れんぼれきさんと", category: "睡眠薬", maker: "エーザイ", tags: ["不眠", "睡眠", "中途覚醒"], rx: true, brandPrice: 93.60),
    .init(genericName: "エスシタロプラムシュウ酸塩", brandName: "レクサプロ", kana: "えすしたろぷらむ", category: "抗うつ薬", maker: "持田製薬", tags: ["うつ", "不安", "SSRI"], rx: true, brandPrice: 103.20),
    .init(genericName: "セルトラリン塩酸塩", brandName: "ジェイゾロフト", kana: "せるとらりん", category: "抗うつ薬", maker: "ヴィアトリス製薬", tags: ["うつ", "不安", "SSRI"], rx: true, brandPrice: 85.50),
    .init(genericName: "パロキセチン塩酸塩水和物", brandName: "パキシル", kana: "ぱろきせちん", category: "抗うつ薬", maker: "グラクソ・スミスクライン", tags: ["うつ", "不安", "SSRI"], rx: true, brandPrice: 74.60),
    .init(genericName: "デュロキセチン塩酸塩", brandName: "サインバルタ", kana: "でゅろきせちん", category: "抗うつ薬", maker: "塩野義製薬", tags: ["うつ", "疼痛", "SNRI"], rx: true, brandPrice: 149.20),
    .init(genericName: "ベンラファキシン塩酸塩", brandName: "イフェクサーSR", kana: "べんらふぁきしん", category: "抗うつ薬", maker: "ファイザー", tags: ["うつ", "不安", "SNRI"], rx: true, brandPrice: 163.40),
    .init(genericName: "アリピプラゾール", brandName: "エビリファイ", kana: "ありぴぷらぞーる", category: "抗精神病薬", maker: "大塚製薬", tags: ["統合失調症", "双極性障害", "抗精神病"], rx: true, brandPrice: 347.50),
    .init(genericName: "クエチアピンフマル酸塩", brandName: "セロクエル", kana: "くえちあぴん", category: "抗精神病薬", maker: "住友ファーマ", tags: ["統合失調症", "双極性障害", "睡眠"], rx: true, brandPrice: 57.20),
    .init(genericName: "リスペリドン", brandName: "リスパダール", kana: "りすぺりどん", category: "抗精神病薬", maker: "ヤンセンファーマ", tags: ["統合失調症", "易刺激性", "抗精神病"], rx: true, brandPrice: 48.80),
    .init(genericName: "オランザピン", brandName: "ジプレキサ", kana: "おらんざぴん", category: "抗精神病薬", maker: "日本イーライリリー", tags: ["統合失調症", "双極性障害", "抗精神病"], rx: true, brandPrice: 203.80),
    .init(genericName: "タムスロシン塩酸塩", brandName: "ハルナール", kana: "たむすろしん", category: "排尿障害治療薬", maker: "アステラス製薬", tags: ["前立腺肥大", "排尿", "頻尿"], rx: true, brandPrice: 62.40),
    .init(genericName: "ナフトピジル", brandName: "フリバス", kana: "なふとぴじる", category: "排尿障害治療薬", maker: "旭化成ファーマ", tags: ["前立腺肥大", "排尿", "頻尿"], rx: true, brandPrice: 32.70),
    .init(genericName: "ソリフェナシンコハク酸塩", brandName: "ベシケア", kana: "そりふぇなじん", category: "排尿障害治療薬", maker: "アステラス製薬", tags: ["過活動膀胱", "頻尿", "尿意切迫"], rx: true, brandPrice: 176.30),
    .init(genericName: "ミラベグロン", brandName: "ベタニス", kana: "みらべぐろん", category: "排尿障害治療薬", maker: "アステラス製薬", tags: ["過活動膀胱", "頻尿", "β3作動"], rx: true, brandPrice: 194.70),
    .init(genericName: "デュタステリド", brandName: "アボルブ", kana: "でゅたすてりど", category: "排尿障害治療薬", maker: "グラクソ・スミスクライン", tags: ["前立腺肥大", "排尿", "5α還元酵素"], rx: true, brandPrice: 101.00),
    .init(genericName: "アレンドロン酸ナトリウム水和物", brandName: "ボナロン", kana: "あれんどろんさん", category: "骨粗鬆症治療薬", maker: "帝人ファーマ", tags: ["骨粗鬆症", "骨折予防", "ビスホスホネート"], rx: true, brandPrice: 278.10),
    .init(genericName: "リセドロン酸ナトリウム水和物", brandName: "アクトネル", kana: "りせどろんさん", category: "骨粗鬆症治療薬", maker: "エーザイ", tags: ["骨粗鬆症", "骨折予防", "ビスホスホネート"], rx: true, brandPrice: 255.40),
    .init(genericName: "エルデカルシトール", brandName: "エディロール", kana: "えるでかるしとーる", category: "骨粗鬆症治療薬", maker: "中外製薬", tags: ["骨粗鬆症", "活性型ビタミンD", "骨"], rx: true, brandPrice: 87.30),
    .init(genericName: "デノスマブ", brandName: "プラリア", kana: "でのすまぶ", category: "骨粗鬆症治療薬", maker: "第一三共", tags: ["骨粗鬆症", "注射", "骨折予防"], rx: true, brandPrice: 27861.00),
    .init(genericName: "レボチロキシンナトリウム水和物", brandName: "チラーヂンS", kana: "れぼちろきしん", category: "甲状腺治療薬", maker: "あすか製薬", tags: ["甲状腺機能低下症", "甲状腺", "補充"], rx: true, brandPrice: 9.30),
    .init(genericName: "チアマゾール", brandName: "メルカゾール", kana: "ちあまぞーる", category: "甲状腺治療薬", maker: "サンノーバ", tags: ["甲状腺機能亢進症", "甲状腺", "抗甲状腺"], rx: true, brandPrice: 10.40),
    .init(genericName: "プロピルチオウラシル", brandName: "チウラジール", kana: "ぷろぴるちおうらしる", category: "甲状腺治療薬", maker: "あすか製薬", tags: ["甲状腺機能亢進症", "妊娠初期", "抗甲状腺"], rx: true, brandPrice: 12.10),
    .init(genericName: "アロプリノール", brandName: "ザイロリック", kana: "あろぷりのーる", category: "痛風治療薬", maker: "サンファーマ", tags: ["痛風", "尿酸", "高尿酸血症"], rx: true, brandPrice: 9.20),
    .init(genericName: "フェブキソスタット", brandName: "フェブリク", kana: "ふぇぶきそすたっと", category: "痛風治療薬", maker: "帝人ファーマ", tags: ["痛風", "尿酸", "高尿酸血症"], rx: true, brandPrice: 59.80),
    .init(genericName: "ベンズブロマロン", brandName: "ユリノーム", kana: "べんずぶろまろん", category: "痛風治療薬", maker: "鳥居薬品", tags: ["痛風", "尿酸", "排泄促進"], rx: true, brandPrice: 14.60),
    .init(genericName: "葛根湯", brandName: "ツムラ葛根湯エキス顆粒", kana: "かっこんとう", category: "漢方製剤", maker: "ツムラ", tags: ["風邪", "肩こり", "漢方"], rx: false, brandPrice: 23.40),
    .init(genericName: "小青竜湯", brandName: "ツムラ小青竜湯エキス顆粒", kana: "しょうせいりゅうとう", category: "漢方製剤", maker: "ツムラ", tags: ["鼻水", "花粉症", "漢方"], rx: false, brandPrice: 28.10),
    .init(genericName: "補中益気湯", brandName: "ツムラ補中益気湯エキス顆粒", kana: "ほちゅうえっきとう", category: "漢方製剤", maker: "ツムラ", tags: ["倦怠感", "食欲低下", "漢方"], rx: true, brandPrice: 31.60),
    .init(genericName: "大建中湯", brandName: "ツムラ大建中湯エキス顆粒", kana: "だいけんちゅうとう", category: "漢方製剤", maker: "ツムラ", tags: ["腹部膨満", "便通", "漢方"], rx: true, brandPrice: 34.20),
    .init(genericName: "抑肝散", brandName: "ツムラ抑肝散エキス顆粒", kana: "よくかんさん", category: "漢方製剤", maker: "ツムラ", tags: ["いらいら", "不眠", "漢方"], rx: true, brandPrice: 29.70),
    .init(genericName: "オロパタジン塩酸塩点眼液", brandName: "パタノール点眼液", kana: "おろぱたじんてんがん", category: "点眼薬", maker: "日本アルコン", tags: ["アレルギー", "目のかゆみ", "点眼"], rx: true, brandPrice: 308.40),
    .init(genericName: "レボフロキサシン点眼液", brandName: "クラビット点眼液", kana: "れぼふろきさしんてんがん", category: "点眼薬", maker: "参天製薬", tags: ["結膜炎", "抗菌", "点眼"], rx: true, brandPrice: 274.80),
    .init(genericName: "ヒアルロン酸ナトリウム点眼液", brandName: "ヒアレイン点眼液", kana: "ひあるろんさんてんがん", category: "点眼薬", maker: "参天製薬", tags: ["ドライアイ", "点眼", "角膜保護"], rx: true, brandPrice: 183.10),
    .init(genericName: "タクロリムス水和物軟膏", brandName: "プロトピック軟膏", kana: "たくろりむすなんこう", category: "外用薬", maker: "マルホ", tags: ["アトピー", "皮膚炎", "外用"], rx: true, brandPrice: 139.20),
    .init(genericName: "ベタメタゾン吉草酸エステル軟膏", brandName: "リンデロンV軟膏", kana: "べためたぞんなんこう", category: "外用薬", maker: "塩野義製薬", tags: ["湿疹", "皮膚炎", "外用"], rx: true, brandPrice: 21.10),
    .init(genericName: "ヘパリン類似物質油性クリーム", brandName: "ヒルドイドソフト", kana: "へぱりんるいじぶっしつ", category: "外用薬", maker: "マルホ", tags: ["保湿", "乾燥", "外用"], rx: true, brandPrice: 28.70)
]

private let supplementalMedicineSeeds: [MedicineSeed] = [
    .init(genericName: "ビペリデン塩酸塩", brandName: "タスモリン", kana: "たすもりん", category: "抗パーキンソン薬", maker: "田辺三菱製薬", tags: ["パーキンソニズム", "アカシジア", "抗コリン"], rx: true, brandPrice: 5.60),
    .init(genericName: "フルニトラゼパム", brandName: "サイレース", kana: "さいれーす", category: "睡眠薬", maker: "エーザイ", tags: ["ロヒプノール", "不眠", "麻酔前投薬", "ベンゾジアゼピン", "向精神薬"], rx: true, brandPrice: 8.60),
    .init(genericName: "オルメサルタン メドキソミル", brandName: "オルメテック", kana: "おるめさるたん", category: "ARB", maker: "第一三共", tags: ["高血圧", "降圧", "ARB"], rx: true, brandPrice: 71.40),
    .init(genericName: "テルミサルタン・アムロジピン配合錠", brandName: "ミカムロ", kana: "みかむろ", category: "ARB", maker: "日本ベーリンガーインゲルハイム", tags: ["高血圧", "配合剤", "降圧"], rx: true, brandPrice: 92.50),
    .init(genericName: "ロサルタンカリウム・ヒドロクロロチアジド配合錠", brandName: "プレミネント", kana: "ぷれみねんと", category: "ARB", maker: "オルガノン", tags: ["高血圧", "配合剤", "利尿"], rx: true, brandPrice: 84.80),
    .init(genericName: "カルシウム拮抗薬配合剤", brandName: "エックスフォージ", kana: "えっくすふぉーじ", category: "カルシウム拮抗薬", maker: "ノバルティスファーマ", tags: ["高血圧", "配合剤", "降圧"], rx: true, brandPrice: 89.60),
    .init(genericName: "ドキサゾシンメシル酸塩", brandName: "カルデナリン", kana: "どきさぞしん", category: "排尿障害治療薬", maker: "ファイザー", tags: ["前立腺肥大", "高血圧", "排尿"], rx: true, brandPrice: 18.20),
    .init(genericName: "ニトログリセリン貼付剤", brandName: "ミリステープ", kana: "にとろぐりせりん", category: "循環器治療薬", maker: "トーアエイヨー", tags: ["狭心症", "胸痛", "血管拡張"], rx: true, brandPrice: 62.80),
    .init(genericName: "硝酸イソソルビド", brandName: "フランドル", kana: "しょうさんいそそるびど", category: "循環器治療薬", maker: "トーアエイヨー", tags: ["狭心症", "胸痛", "血管拡張"], rx: true, brandPrice: 14.20),
    .init(genericName: "アミオダロン塩酸塩", brandName: "アンカロン", kana: "あみおだろん", category: "抗不整脈薬", maker: "サノフィ", tags: ["不整脈", "心房細動", "VT"], rx: true, brandPrice: 95.40),
    .init(genericName: "ピルシカイニド塩酸塩水和物", brandName: "サンリズム", kana: "ぴるしかいにど", category: "抗不整脈薬", maker: "第一三共", tags: ["不整脈", "心房細動", "頻拍"], rx: true, brandPrice: 72.30),
    .init(genericName: "ジゴキシン", brandName: "ジゴシン", kana: "じごきしん", category: "循環器治療薬", maker: "中外製薬", tags: ["心不全", "頻脈", "AF"], rx: true, brandPrice: 9.60),
    .init(genericName: "カルボプラチン", brandName: "パラプラチン", kana: "かるぼぷらちん", category: "抗がん剤", maker: "ブリストル・マイヤーズ スクイブ", tags: ["がん", "化学療法", "白金製剤"], rx: true, brandPrice: 4718.00),
    .init(genericName: "ドセタキセル", brandName: "タキソテール", kana: "どせたきせる", category: "抗がん剤", maker: "サノフィ", tags: ["がん", "化学療法", "タキサン"], rx: true, brandPrice: 9238.00),
    .init(genericName: "レトロゾール", brandName: "フェマーラ", kana: "れとろぞーる", category: "抗がん剤", maker: "ノバルティスファーマ", tags: ["乳がん", "ホルモン療法", "抗がん剤"], rx: true, brandPrice: 284.70),
    .init(genericName: "タモキシフェンクエン酸塩", brandName: "ノルバデックス", kana: "たもきしふぇん", category: "抗がん剤", maker: "アストラゼネカ", tags: ["乳がん", "ホルモン療法", "抗がん剤"], rx: true, brandPrice: 98.60),
    .init(genericName: "レボフロキサシン水和物点耳液", brandName: "クラビット点耳液", kana: "くらびっとてんじえき", category: "耳鼻科用薬", maker: "第一三共", tags: ["中耳炎", "耳痛", "抗菌"], rx: true, brandPrice: 218.40),
    .init(genericName: "モメタゾンフランカルボン酸エステル点鼻液", brandName: "ナゾネックス", kana: "なぞねっくす", category: "耳鼻科用薬", maker: "MSD", tags: ["花粉症", "鼻炎", "点鼻"], rx: true, brandPrice: 426.50),
    .init(genericName: "フルチカゾンプロピオン酸エステル点鼻液", brandName: "フルナーゼ", kana: "ふるなーぜ", category: "耳鼻科用薬", maker: "グラクソ・スミスクライン", tags: ["花粉症", "鼻炎", "点鼻"], rx: true, brandPrice: 393.80),
    .init(genericName: "アセチルシステイン", brandName: "チスタニン", kana: "あせちるしすていん", category: "去痰薬", maker: "鶴原製薬", tags: ["痰", "咳", "去痰"], rx: true, brandPrice: 8.40),
    .init(genericName: "ジメモルファンリン酸塩", brandName: "アストミン", kana: "じめもるふぁん", category: "鎮咳薬", maker: "アルフレッサファーマ", tags: ["咳", "風邪", "鎮咳"], rx: true, brandPrice: 8.70),
    .init(genericName: "L-カルボシステインシロップ", brandName: "ムコダインシロップ", kana: "むこだいんしろっぷ", category: "去痰薬", maker: "杏林製薬", tags: ["子ども", "痰", "咳"], rx: true, brandPrice: 8.90),
    .init(genericName: "メキタジン", brandName: "ゼスラン", kana: "めきたじん", category: "抗ヒスタミン薬", maker: "旭化成ファーマ", tags: ["花粉症", "鼻炎", "蕁麻疹"], rx: true, brandPrice: 13.40),
    .init(genericName: "ベポタスチンベシル酸塩", brandName: "タリオン", kana: "べぽたすちん", category: "抗ヒスタミン薬", maker: "田辺三菱製薬", tags: ["花粉症", "鼻炎", "かゆみ"], rx: true, brandPrice: 38.80),
    .init(genericName: "トラネキサム酸", brandName: "トランサミン", kana: "とらねきさむさん", category: "止血薬", maker: "第一三共", tags: ["出血", "のどの痛み", "炎症"], rx: true, brandPrice: 9.40),
    .init(genericName: "カルバゾクロムスルホン酸ナトリウム水和物", brandName: "アドナ", kana: "あどな", category: "止血薬", maker: "田辺三菱製薬", tags: ["出血", "止血", "毛細血管"], rx: true, brandPrice: 6.90),
    .init(genericName: "リファキシミン", brandName: "リフキシマ", kana: "りふぁきしみん", category: "消化器治療薬", maker: "あすか製薬", tags: ["高アンモニア血症", "肝性脳症", "腸内細菌"], rx: true, brandPrice: 385.20),
    .init(genericName: "ミヤBM細粒", brandName: "ミヤBM細粒", kana: "みやびーえむさいりゅう", category: "整腸剤", maker: "ミヤリサン製薬", tags: ["整腸", "子ども", "下痢"], rx: true, brandPrice: 5.90),
    .init(genericName: "ポリエチレングリコール製剤", brandName: "モビコール", kana: "もびこーる", category: "下剤", maker: "EAファーマ", tags: ["便秘", "慢性便秘", "浸透圧"], rx: true, brandPrice: 82.10),
    .init(genericName: "ナルデメジントシル酸塩", brandName: "スインプロイク", kana: "なるでめじん", category: "下剤", maker: "塩野義製薬", tags: ["便秘", "オピオイド", "排便"], rx: true, brandPrice: 272.00),
    .init(genericName: "アズレンスルホン酸ナトリウム・L-グルタミン配合顆粒", brandName: "マーズレンS", kana: "まーずれん", category: "胃粘膜保護薬", maker: "寿製薬", tags: ["胃炎", "胃痛", "胃粘膜"], rx: true, brandPrice: 12.50),
    .init(genericName: "レバミピド", brandName: "ムコスタ", kana: "ればみぴど", category: "胃粘膜保護薬", maker: "大塚製薬", tags: ["胃炎", "胃痛", "粘膜保護"], rx: true, brandPrice: 13.20),
    .init(genericName: "イトプリド塩酸塩", brandName: "ガナトン", kana: "いとぷりど", category: "消化管運動改善薬", maker: "アボットジャパン", tags: ["胃もたれ", "食欲不振", "消化不良"], rx: true, brandPrice: 17.10),
    .init(genericName: "エンテカビル水和物", brandName: "バラクルード", kana: "えんてかびる", category: "抗ウイルス薬", maker: "ブリストル・マイヤーズ スクイブ", tags: ["B型肝炎", "抗ウイルス", "肝機能"], rx: true, brandPrice: 1166.40),
    .init(genericName: "ソホスブビル・ベルパタスビル配合錠", brandName: "エプクルーサ", kana: "えぷくるーさ", category: "抗ウイルス薬", maker: "ギリアド・サイエンシズ", tags: ["C型肝炎", "抗ウイルス", "配合剤"], rx: true, brandPrice: 61286.70),
    .init(genericName: "プレドニゾロン", brandName: "プレドニン", kana: "ぷれどにぞろん", category: "ステロイド薬", maker: "シオノギファーマ", tags: ["炎症", "自己免疫", "アレルギー"], rx: true, brandPrice: 7.90),
    .init(genericName: "デキサメタゾン", brandName: "デカドロン", kana: "できさめたぞん", category: "ステロイド薬", maker: "日医工", tags: ["炎症", "浮腫", "ステロイド"], rx: true, brandPrice: 9.10),
    .init(genericName: "ヒドロコルチゾン酪酸エステル軟膏", brandName: "ロコイド軟膏", kana: "ろこいどなんこう", category: "外用薬", maker: "鳥居薬品", tags: ["湿疹", "皮膚炎", "かゆみ"], rx: true, brandPrice: 17.40),
    .init(genericName: "ジフルプレドナート軟膏", brandName: "マイザー軟膏", kana: "まいざーなんこう", category: "外用薬", maker: "マルホ", tags: ["湿疹", "皮膚炎", "ステロイド"], rx: true, brandPrice: 23.10),
    .init(genericName: "アダパレン", brandName: "ディフェリンゲル", kana: "でぃふぇりん", category: "外用薬", maker: "ガルデルマ", tags: ["にきび", "外用", "皮膚"], rx: true, brandPrice: 225.60),
    .init(genericName: "ベンゾイル過酸化物", brandName: "ベピオゲル", kana: "べぴおげる", category: "外用薬", maker: "マルホ", tags: ["にきび", "外用", "皮膚"], rx: true, brandPrice: 185.40),
    .init(genericName: "ラタノプロスト点眼液", brandName: "キサラタン点眼液", kana: "きさらたんてんがん", category: "点眼薬", maker: "ファイザー", tags: ["緑内障", "眼圧", "点眼"], rx: true, brandPrice: 404.10),
    .init(genericName: "タフルプロスト点眼液", brandName: "タプロス点眼液", kana: "たぷろすてんがん", category: "点眼薬", maker: "参天製薬", tags: ["緑内障", "眼圧", "点眼"], rx: true, brandPrice: 396.20),
    .init(genericName: "チモロールマレイン酸塩点眼液", brandName: "チモプトール点眼液", kana: "ちもろーるてんがん", category: "点眼薬", maker: "参天製薬", tags: ["緑内障", "眼圧", "点眼"], rx: true, brandPrice: 228.70),
    .init(genericName: "開始液（1）", brandName: "ソリタ－T1号輸液", kana: "そりたてぃーわん", category: "輸液用電解質液", maker: "エイワイファーマ", tags: ["ソリタT1", "ソリタ-T1", "SOLITA-T No.1", "点滴", "輸液", "開始液", "脱水", "電解質補給"], rx: true, brandPrice: 184.00),
    .init(genericName: "脱水補給液（4）", brandName: "ソリタ－T2号輸液", kana: "そりたてぃーつー", category: "輸液用電解質液", maker: "エイワイファーマ", tags: ["ソリタT2", "ソリタ-T2", "SOLITA-T No.2", "点滴", "輸液", "脱水補給液", "脱水", "電解質補正"], rx: true, brandPrice: 277.00),
    .init(genericName: "維持液（3）", brandName: "ソリタ－T3号輸液", kana: "そりたてぃーすりー", category: "輸液用電解質液", maker: "エイワイファーマ", tags: ["ソリタT3", "ソリタ-T3", "SOLITA-T No.3", "点滴", "輸液", "維持液", "水分補給", "電解質補給"], rx: true, brandPrice: 183.00),
    .init(genericName: "維持液（糖加）", brandName: "ソリタ－T3号G輸液", kana: "そりたてぃーすりーじー", category: "輸液用電解質液", maker: "エイワイファーマ", tags: ["ソリタT3G", "ソリタ-T3G", "SOLITA-T No.3G", "点滴", "輸液", "維持液", "糖加", "電解質補給"], rx: true, brandPrice: 226.00),
    .init(genericName: "術後回復液（2）", brandName: "ソリタ－T4号輸液", kana: "そりたてぃーふぉー", category: "輸液用電解質液", maker: "エイワイファーマ", tags: ["ソリタT4", "ソリタ-T4", "SOLITA-T No.4", "点滴", "輸液", "術後回復液", "乳幼児手術", "電解質補給"], rx: true, brandPrice: 256.00),
    .init(genericName: "アセトアミノフェン注射液", brandName: "アセリオ静注液1000mg", kana: "あせりおじょうちゅう", category: "注射用解熱鎮痛薬", maker: "テルモ", tags: ["アセトアミノフェン", "静注", "注射", "点滴", "疼痛", "発熱", "術後痛"], rx: true, brandPrice: 323.00),
    .init(genericName: "セファゾリンナトリウム水和物注射用", brandName: "セファメジンα注射用1g", kana: "せふぁめじん", category: "注射用抗菌薬", maker: "LTLファーマ", tags: ["セファゾリン", "静注", "筋注", "注射", "点滴", "セフェム", "周術期", "感染症"], rx: true, brandPrice: 346.00),
    .init(genericName: "セフトリアキソンナトリウム水和物静注用", brandName: "ロセフィン静注用1g", kana: "ろせふぃん", category: "注射用抗菌薬", maker: "太陽ファルマ", tags: ["セフトリアキソン", "静注", "注射", "点滴", "セフェム", "肺炎", "尿路感染症"], rx: true, brandPrice: 422.00),
    .init(genericName: "メロペネム水和物注射用", brandName: "メロペン点滴用バイアル0.5g", kana: "めろぺん", category: "注射用抗菌薬", maker: "住友ファーマ", tags: ["メロペネム", "点滴", "静注", "注射", "カルバペネム", "重症感染症", "発熱性好中球減少症"], rx: true, brandPrice: 853.00),
    .init(genericName: "タゾバクタム・ピペラシリン水和物静注用", brandName: "ゾシン静注用4.5", kana: "ぞしん", category: "注射用抗菌薬", maker: "大鵬薬品工業", tags: ["タゾピペ", "ピペタゾ", "静注", "注射", "点滴", "広域抗菌薬", "発熱性好中球減少症"], rx: true, brandPrice: 1160.00),
    .init(genericName: "バンコマイシン塩酸塩静注用", brandName: "バンコマイシン塩酸塩点滴静注用0.5g", kana: "ばんこまいしん", category: "注射用抗菌薬", maker: "Meiji Seika ファルマ", tags: ["バンコマイシン", "点滴", "静注", "注射", "MRSA", "TDM", "グリコペプチド"], rx: true, brandPrice: 710.00),
    .init(genericName: "フロセミド注射液", brandName: "ラシックス注20mg", kana: "らしっくすちゅう", category: "注射用利尿薬", maker: "サノフィ", tags: ["フロセミド", "注射", "静注", "ループ利尿薬", "心不全", "浮腫", "利尿"], rx: true, brandPrice: 64.00),
    .init(genericName: "ヒドロコルチゾンコハク酸エステルナトリウム注射用", brandName: "ソル・コーテフ注射用100mg", kana: "そるこーてふ", category: "注射用ステロイド", maker: "ファイザー", tags: ["ヒドロコルチゾン", "静注", "注射", "副腎皮質ホルモン", "アナフィラキシー", "喘息発作", "副腎不全"], rx: true, brandPrice: 264.00),
    .init(genericName: "メトクロプラミド塩酸塩注射液", brandName: "プリンペラン注射液10mg", kana: "ぷりんぺらんちゅう", category: "注射用制吐薬", maker: "日医工", tags: ["メトクロプラミド", "注射", "静注", "筋注", "制吐", "悪心", "嘔吐"], rx: true, brandPrice: 68.00),
    .init(genericName: "ミダゾラム注射液", brandName: "ドルミカム注射液10mg", kana: "どるみかむ", category: "麻酔・鎮静薬", maker: "丸石製薬", tags: ["ミダゾラム", "注射", "静注", "鎮静", "麻酔前投薬", "人工呼吸中鎮静", "ベンゾジアゼピン"], rx: true, brandPrice: 115.00),
    .init(genericName: "プロポフォール注射液", brandName: "プロポフォール1%静注20mL", kana: "ぷろぽふぉーる", category: "麻酔・鎮静薬", maker: "日医工", tags: ["プロポフォール", "静注", "注射", "全身麻酔", "鎮静", "ICU", "乳濁性注射液"], rx: true, brandPrice: 594.00),
    .init(genericName: "アドレナリンキット", brandName: "アドレナリン注0.1%シリンジ「テルモ」", kana: "あどれなりんしりんじ", category: "救急循環作動薬", maker: "テルモ", tags: ["エピネフリン", "アドレナリン", "シリンジ", "注射", "心停止", "ショック", "アナフィラキシー"], rx: true, brandPrice: 353.00),
    .init(genericName: "ノルアドレナリン注射液", brandName: "ノルアドリナリン注1mg", kana: "のるあどりなりん", category: "救急循環作動薬", maker: "アルフレッサファーマ", tags: ["ノルアドレナリン", "ノルエピネフリン", "注射", "静注", "昇圧薬", "ショック", "急性低血圧"], rx: true, brandPrice: 100.00),
    .init(genericName: "リスペリドン内用液", brandName: "リスパダール内用液", kana: "りすぱだーるないようえき", category: "抗精神病薬", maker: "ヤンセンファーマ", tags: ["統合失調症", "易刺激性", "液剤"], rx: true, brandPrice: 58.10),
    .init(genericName: "炭酸リチウム", brandName: "リーマス", kana: "たんさんりちうむ", category: "精神科治療薬", maker: "大日本住友製薬", tags: ["双極性障害", "気分安定", "躁状態"], rx: true, brandPrice: 9.80),
    .init(genericName: "バルプロ酸ナトリウム", brandName: "デパケン", kana: "ばるぷろさん", category: "精神科治療薬", maker: "協和キリン", tags: ["てんかん", "双極性障害", "気分安定"], rx: true, brandPrice: 10.20),
    .init(genericName: "ラモトリギン", brandName: "ラミクタール", kana: "らもとりぎん", category: "精神科治療薬", maker: "グラクソ・スミスクライン", tags: ["双極性障害", "てんかん", "気分安定"], rx: true, brandPrice: 123.80)
]

private func unit(for category: String) -> String {
    if category == "点眼薬" { return "mL" }
    if category == "外用薬" { return "g" }
    if category == "輸液用電解質液" { return "袋" }
    if category == "インスリン製剤" || category == "吸入配合剤" || category == "気管支拡張薬" { return "キット" }
    if category == "骨粗鬆症治療薬" && category.contains("注射") { return "筒" }
    return "錠"
}

private func unit(for seed: MedicineSeed) -> String {
    if seed.category == "輸液用電解質液" { return "袋" }
    if seed.brandName.contains("シリンジ") { return "筒" }
    if seed.brandName.contains("バッグ") || seed.brandName.contains("キット") { return "キット" }
    if seed.brandName.contains("注射液") || seed.brandName.contains("注20mg") || seed.brandName.contains("注1mg") || seed.brandName.contains("静注液") || seed.brandName.contains("静注20mL") { return "管" }
    if seed.category.hasPrefix("注射用") || seed.brandName.contains("注射用") || seed.brandName.contains("静注用") || seed.brandName.contains("バイアル") { return "瓶" }
    return unit(for: seed.category)
}

private func isInjectionCategory(_ category: String) -> Bool {
    category.hasPrefix("注射用")
        || category == "麻酔・鎮静薬"
        || category == "救急循環作動薬"
}

private func mechanism(for category: String) -> String {
    switch category {
    case "ARB": return "アンジオテンシンII AT1受容体拮抗により血管収縮、アルドステロン分泌、心血管・腎リモデリングを抑制します。"
    case "ACE阻害薬": return "ACE阻害によりアンジオテンシンII産生を低下させるとともに、ブラジキニン分解抑制を介して血管拡張作用を示します。"
    case "β遮断薬": return "主としてβ1受容体遮断により心拍数、心収縮力、レニン分泌を低下させ、心筋酸素需要と交感神経活性を抑制します。"
    case "利尿薬": return "尿細管各部位のイオン輸送体に作用し、Na・水再吸収を抑制することで循環血漿量、うっ血、血圧を改善します。"
    case "脂質異常症治療薬": return "HMG-CoA還元酵素阻害、コレステロール吸収抑制、PPARα活性化などを介して脂質代謝を是正します。"
    case "抗凝固薬", "抗血小板薬": return "凝固因子活性阻害または血小板活性化経路遮断により血栓形成を抑制し、塞栓・再発イベントを予防します。"
    case "糖尿病治療薬", "インスリン製剤": return "インスリン分泌促進、肝糖産生抑制、インスリン抵抗性改善、尿糖排泄促進、外因性インスリン補充など多様な機序で血糖を是正します。"
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬": return "壁細胞のH+/K+-ATPase阻害、K+競合的酸分泌抑制、またはH2受容体遮断により胃酸分泌を低下させます。"
    case "整腸剤", "止瀉薬", "下剤", "消化管運動改善薬", "胃粘膜保護薬", "制吐薬": return "腸管運動、腸液分泌、粘膜防御、ドパミン・セロトニン系などへ作用し、消化器症状を改善します。"
    case "抗菌薬", "抗ウイルス薬": return "細胞壁合成、蛋白合成、核酸合成、ウイルス複製過程など病原体特異的な標的を阻害します。"
    case "注射用抗菌薬": return "細胞壁合成阻害やβラクタマーゼ阻害などにより、重症感染症や入院治療で必要な抗菌活性を点滴・静注で発揮します。"
    case "注射用解熱鎮痛薬": return "中枢性の解熱・鎮痛作用を示し、経口摂取が難しい場合や周術期の疼痛・発熱に静注で使用します。"
    case "注射用利尿薬": return "ヘンレループ上行脚でNa-K-2Cl共輸送体を阻害し、速やかな利尿により肺うっ血や浮腫を改善します。"
    case "注射用ステロイド": return "グルココルチコイド受容体を介して炎症性サイトカイン産生や免疫反応を抑え、急性炎症・アレルギー・副腎不全に対応します。"
    case "注射用制吐薬": return "消化管運動改善やドパミン受容体遮断により、悪心・嘔吐や胃内容排出遅延を改善します。"
    case "麻酔・鎮静薬": return "GABA作動性抑制や中枢神経抑制を介して、麻酔導入・維持、処置時鎮静、人工呼吸中の鎮静に用います。"
    case "救急循環作動薬": return "α・βアドレナリン受容体刺激により血管収縮、心拍出量増加、気管支拡張をもたらし、ショックや心停止時の循環を支えます。"
    case "抗ヒスタミン薬": return "末梢H1受容体遮断を主として、ヒスタミン依存性の血管透過性亢進、くしゃみ、鼻汁、掻痒を抑制します。"
    case "抗喘息薬", "気管支拡張薬", "吸入配合剤", "去痰薬", "鎮咳薬": return "気道炎症抑制、β2刺激による気管支拡張、ロイコトリエン経路抑制、分泌物粘稠度低下などを介して呼吸器症状を改善します。"
    case "抗不安薬", "睡眠薬", "抗うつ薬", "抗精神病薬": return "GABA、セロトニン、ノルアドレナリン、ドパミン受容体・輸送体系に作用し、中枢神経伝達を調整します。"
    case "排尿障害治療薬": return "α1受容体遮断、抗コリン作用、β3受容体刺激、5α還元酵素阻害などにより蓄尿・排尿機能を調整します。"
    case "骨粗鬆症治療薬": return "骨吸収抑制、破骨細胞機能抑制、活性型ビタミンD作用を介して骨代謝バランスを改善します。"
    case "甲状腺治療薬": return "甲状腺ホルモン補充、または甲状腺ホルモン合成阻害により甲状腺機能異常を補正します。"
    case "痛風治療薬": return "キサンチンオキシダーゼ阻害による尿酸産生抑制、または尿酸排泄促進により血清尿酸値を低下させます。"
    case "漢方製剤": return "複数生薬の相乗作用により自律神経、免疫、循環、消化機能などへ多面的に作用すると考えられています。"
    case "点眼薬", "外用薬": return "有効成分を局所へ直接送達し、炎症、アレルギー、感染、乾燥などの病態に応じて標的部位で作用します。"
    default: return "代表的な薬効群として、薬理学的標的と臨床上の役割が理解しやすいよう整理しています。"
    }
}

private func actionSummary(for category: String) -> String {
    switch category {
    case "解熱鎮痛薬", "解熱鎮痛消炎剤", "鎮痛薬", "鎮痛補助薬":
        return "疼痛シグナルや炎症性メディエーターを抑制し、急性痛から慢性疼痛まで症状の質に応じて使い分けます。NSAIDsでは抗炎症作用も期待でき、神経障害性疼痛薬では中枢感作の是正を狙います。"
    case "カルシウム拮抗薬", "ARB", "ACE阻害薬", "β遮断薬", "利尿薬":
        return "循環動態、血管トーン、体液量、レニン・アンジオテンシン系のいずれかに介入し、血圧・心負荷・うっ血を多面的にコントロールします。"
    case "脂質異常症治療薬":
        return "スタチン系は肝コレステロール合成抑制、エゼチミブは腸管吸収抑制、EPAやフィブラートはTG改善を担い、脂質異常の型で選択します。"
    case "抗凝固薬", "抗血小板薬":
        return "凝固カスケードあるいは血小板活性化経路を抑制して血栓形成を予防します。適応、腎機能、出血リスク、併用薬で選択が変わります。"
    case "糖尿病治療薬", "インスリン製剤":
        return "インスリン分泌促進、糖新生抑制、尿糖排泄促進、インスリン補充など作用点が異なるため、病態と合併症を見ながら併用設計します。"
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return "酸分泌抑制の強さと立ち上がりが異なります。PPIは持続抑制、P-CABは速効性と強力な抑制、H2ブロッカーは補助的位置づけで使われます。"
    case "抗菌薬", "抗ウイルス薬":
        return "微生物の増殖を抑えるだけでなく、組織移行性、PK/PD、耐性化リスクを踏まえて適正使用することが重要です。"
    case "注射用抗菌薬":
        return "入院・救急・周術期で使う注射抗菌薬です。感染巣、重症度、培養結果、腎機能、TDMの必要性を踏まえて選択・調整します。"
    case "注射用解熱鎮痛薬", "注射用制吐薬":
        return "経口投与が難しい場面や急性期に、症状を速やかに抑える目的で静注・筋注などにより使用します。"
    case "注射用利尿薬", "注射用ステロイド", "救急循環作動薬":
        return "急性期の循環、炎症、呼吸、体液管理に関わる注射薬です。バイタル、検査値、投与速度、投与経路を確認しながら使います。"
    case "麻酔・鎮静薬":
        return "麻酔導入・維持、処置時鎮静、ICU鎮静で用いる注射薬です。呼吸抑制や循環抑制に備え、監視下で投与します。"
    case "抗ヒスタミン薬", "抗喘息薬", "気管支拡張薬", "吸入配合剤":
        return "アレルギー炎症、ロイコトリエン経路、気管支平滑筋収縮に介入し、症状緩和と増悪予防の両方を狙います。"
    case "輸液用電解質液":
        return "水分、ナトリウム、カリウム、乳酸塩、ブドウ糖などを病態に応じて補給し、循環血漿量と電解質バランスを点滴で調整します。"
    case "抗不安薬", "睡眠薬", "抗うつ薬", "抗精神病薬":
        return "GABA、セロトニン、ノルアドレナリン、ドパミンなど中枢神経伝達系に作用し、症状の種類と副作用プロファイルに応じて選択します。"
    default:
        return "主要薬としての位置づけを理解しやすいよう、臨床での役割と使い分けの要点を簡潔に整理しています。"
    }
}

private func indications(for seed: MedicineSeed) -> [String] {
    switch seed.category {
    case "ARB", "ACE阻害薬", "β遮断薬", "利尿薬", "カルシウム拮抗薬":
        return ["高血圧", "心不全", "循環器疾患の管理"]
    case "脂質異常症治療薬":
        return ["脂質異常症", "動脈硬化リスク低減"]
    case "抗凝固薬", "抗血小板薬":
        return ["血栓塞栓症予防", "脳梗塞・心筋梗塞再発予防"]
    case "糖尿病治療薬", "インスリン製剤":
        return ["2型糖尿病", "血糖コントロール"]
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return ["逆流性食道炎", "胃潰瘍", "胃酸関連症状"]
    case "整腸剤", "止瀉薬", "下剤":
        return ["便秘", "下痢", "便通異常"]
    case "消化管運動改善薬", "胃粘膜保護薬", "制吐薬":
        return ["胃もたれ", "吐き気", "胃部不快感"]
    case "抗菌薬", "抗ウイルス薬":
        return ["感染症"]
    case "注射用抗菌薬":
        return ["重症感染症", "肺炎・尿路感染症・腹腔内感染症", "敗血症", "周術期感染予防"]
    case "注射用解熱鎮痛薬":
        return ["疼痛", "発熱", "経口投与が困難な場合の解熱・鎮痛"]
    case "注射用利尿薬":
        return ["急性心不全", "浮腫", "肺うっ血"]
    case "注射用ステロイド":
        return ["急性副腎皮質機能不全", "アナフィラキシー補助治療", "喘息発作", "炎症性疾患"]
    case "注射用制吐薬":
        return ["悪心・嘔吐", "消化器機能異常", "検査・処置時の消化管運動調整"]
    case "麻酔・鎮静薬":
        return ["全身麻酔の導入・維持", "処置時鎮静", "人工呼吸中の鎮静"]
    case "救急循環作動薬":
        return ["ショック", "急性低血圧", "心停止の補助治療", "アナフィラキシー"]
    case "抗ヒスタミン薬":
        return ["アレルギー性鼻炎", "蕁麻疹", "かゆみ"]
    case "抗喘息薬", "気管支拡張薬", "吸入配合剤":
        return ["気管支喘息", "咳", "呼吸苦"]
    case "去痰薬", "鎮咳薬":
        return ["咳", "痰"]
    case "抗不安薬":
        return ["不安", "緊張", "パニック症状"]
    case "睡眠薬":
        return ["不眠症"]
    case "抗うつ薬":
        return ["うつ状態", "不安障害"]
    case "抗精神病薬":
        return ["統合失調症", "双極性障害"]
    case "排尿障害治療薬":
        return ["前立腺肥大症", "過活動膀胱", "頻尿"]
    case "骨粗鬆症治療薬":
        return ["骨粗鬆症", "骨折予防"]
    case "甲状腺治療薬":
        return ["甲状腺機能異常"]
    case "痛風治療薬":
        return ["高尿酸血症", "痛風"]
    case "漢方製剤":
        return ["体質や症状に応じた漢方治療"]
    case "点眼薬":
        return ["眼の炎症", "アレルギー", "ドライアイ"]
    case "外用薬":
        return ["湿疹", "皮膚炎", "乾燥"]
    case "輸液用電解質液":
        if seed.brandName.contains("T1") {
            return ["脱水症や病態不明時の水分・電解質の初期補給", "手術前後の水分・電解質補給"]
        }
        if seed.brandName.contains("T2") {
            return ["脱水症の水分・電解質補給・補正", "手術前後の水分・電解質補給・補正"]
        }
        if seed.brandName.contains("T4") {
            return ["術後早期の水分・電解質補給", "乳幼児手術に関連する水分・電解質補給", "カリウム貯留が懸念される場合の補液"]
        }
        return ["経口摂取不能または不十分な場合の水分・電解質の補給・維持"]
    default:
        return [seed.category]
    }
}

private func dosage(for category: String) -> String {
    switch category {
    case "解熱鎮痛薬", "解熱鎮痛消炎剤", "鎮痛薬", "鎮痛補助薬":
        return "通常、症状の強さと安全性を見ながら定期投与または頓用で使用します。NSAIDsでは消化管・腎リスクを踏まえて最小有効量、神経障害性疼痛薬では少量開始・漸増が基本です。"
    case "カルシウム拮抗薬", "ARB", "ACE阻害薬", "β遮断薬", "利尿薬":
        return "通常、1日1回製剤を中心に開始し、家庭血圧・外来血圧・脈拍・腎機能・電解質を見ながら段階的に調整します。高齢者では過降圧や脱水に注意が必要です。"
    case "糖尿病治療薬":
        return "通常、低血糖や消化器症状、腎機能の影響を見ながら少量開始または標準量で導入し、HbA1c・食後高血糖・体重変化を踏まえて増減します。"
    case "吸入配合剤", "気管支拡張薬":
        return "通常、用法に従って吸入します。症状や製剤規格により回数が異なります。"
    case "点眼薬":
        return "通常、1回1滴を1日数回点眼します。レンズ装用時は使用方法を確認してください。"
    case "外用薬":
        return "通常、患部に適量を塗布します。症状や部位に応じて回数を調整します。"
    case "インスリン製剤":
        return "通常、血糖値や食事量に応じて単位数を調整して使用します。"
    case "輸液用電解質液":
        return "通常成人、1回500〜1000mLを点滴静注します。投与速度は成人で1時間あたり300〜500mL、小児では1時間あたり50〜100mLを目安に、年齢・症状・体重・尿量により調整します。"
    case let category where isInjectionCategory(category):
        return "注射薬の用量・投与速度・希釈方法は薬剤、適応、体重、腎機能、循環動態で大きく変わります。必ず添付文書・院内手順・処方指示に従い、静注、点滴静注、筋注、皮下注など投与経路を確認します。"
    default:
        return "通常、症状や年齢に応じて1日1〜3回で調整します。詳細は添付文書または処方指示に従います。"
    }
}

private func dosageNotes(for category: String) -> [String] {
    switch category {
    case "解熱鎮痛薬", "解熱鎮痛消炎剤", "鎮痛薬", "鎮痛補助薬":
        return ["頓用と定期投与を区別して指示する", "高齢者・腎機能低下では減量や投与間隔延長を検討", "NSAIDsでは胃薬併用や脱水回避も重要"]
    case "カルシウム拮抗薬", "ARB", "ACE阻害薬", "β遮断薬", "利尿薬":
        return ["導入後1〜2週間で血圧・脈拍・腎機能を再確認", "利尿薬・RA系阻害薬ではK値とCr変動を追う", "急な中止で反跳や増悪を起こす薬に注意"]
    case "脂質異常症治療薬":
        return ["目標LDL/TGに応じて薬効群を選択", "筋症状や肝機能異常の確認を定期的に行う"]
    case "抗凝固薬", "抗血小板薬":
        return ["腎機能・年齢・体重で用量が変わる薬剤がある", "出血時対応と休薬ルールを事前に共有する"]
    case "糖尿病治療薬", "インスリン製剤":
        return ["低血糖リスクの高い薬は食事摂取量と連動して調整", "SGLT2阻害薬ではシックデイルールを指導", "インスリンは自己注射手技とSMBG/CGMの理解が重要"]
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return ["PPIは食前投与が基本の製剤が多い", "長期継続時は必要性を定期見直し", "除菌や逆流性食道炎では治療期間を明確にする"]
    case "抗菌薬", "抗ウイルス薬":
        return ["腎機能に応じた用量調整が必要な薬が多い", "投与日数の過不足は耐性化や再燃に直結する", "培養結果や症状改善に応じてde-escalationを検討"]
    case "抗ヒスタミン薬", "抗喘息薬", "気管支拡張薬", "吸入配合剤":
        return ["眠気や吸入手技を処方時に確認", "コントローラー薬とレスキュー薬を区別して説明"]
    case "輸液用電解質液":
        return ["投与前後で尿量、体重、浮腫、呼吸状態を確認する", "Na、K、Cl、血糖、腎機能を病態に応じて確認する", "心不全・腎機能障害・高カリウム血症では過量投与や電解質変動に注意する"]
    case "注射用抗菌薬":
        return ["培養採取後に開始し、感受性結果でde-escalationを検討する", "腎機能に応じて投与量・投与間隔を調整する", "バンコマイシンなどはTDMを検討する"]
    case "麻酔・鎮静薬", "救急循環作動薬":
        return ["投与中は呼吸・血圧・心拍・SpO2を継続監視する", "急変時に気道確保、酸素投与、蘇生対応ができる環境で使う", "投与速度や希釈濃度をダブルチェックする"]
    case let category where isInjectionCategory(category):
        return ["投与経路、希釈方法、投与速度を確認する", "アレルギー歴、腎機能、肝機能、併用薬を確認する", "投与中のバイタルと注射部位反応を観察する"]
    default:
        return ["腎機能・肝機能・年齢・併用薬で個別調整が必要です", "実際の処方設計は添付文書・ガイドライン・患者背景と合わせて判断します"]
    }
}

private func monitoring(for category: String) -> [String] {
    switch category {
    case "ARB", "ACE阻害薬", "β遮断薬", "利尿薬", "カルシウム拮抗薬":
        return ["血圧", "脈拍", "腎機能", "電解質"]
    case "脂質異常症治療薬":
        return ["脂質値", "肝機能", "筋肉痛の有無"]
    case "抗凝固薬", "抗血小板薬":
        return ["出血症状", "貧血", "腎機能"]
    case "糖尿病治療薬", "インスリン製剤":
        return ["血糖値", "HbA1c", "低血糖症状", "腎機能"]
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return ["症状改善", "下痢や腹部症状", "長期使用時の電解質"]
    case "抗菌薬", "抗ウイルス薬":
        return ["症状の改善", "発疹", "消化器症状", "腎機能"]
    case "注射用抗菌薬":
        return ["体温", "白血球/CRP", "腎機能", "肝機能", "発疹", "下痢", "TDM対象薬の血中濃度"]
    case "注射用利尿薬", "救急循環作動薬":
        return ["血圧", "心拍", "尿量", "電解質", "腎機能", "呼吸状態"]
    case "麻酔・鎮静薬":
        return ["呼吸数", "SpO2", "血圧", "心拍", "鎮静深度", "覚醒状況"]
    case let category where isInjectionCategory(category):
        return ["バイタル", "注射部位", "アレルギー症状", "腎機能", "肝機能"]
    case "抗ヒスタミン薬", "抗不安薬", "睡眠薬":
        return ["眠気", "ふらつき", "日中の活動性"]
    case "輸液用電解質液":
        return ["尿量", "体重", "浮腫", "呼吸状態", "Na/K/Cl", "血糖", "腎機能"]
    default:
        return ["症状の改善", "副作用の有無"]
    }
}

private func sideEffects(for category: String) -> [(icon: String, name: String, detail: String)] {
    switch category {
    case "ARB", "ACE阻害薬", "β遮断薬", "利尿薬", "カルシウム拮抗薬":
        return [("🩺", "血圧低下", "立ちくらみやふらつきが出ることがあります。"), ("💧", "電解質変動", "利尿薬では脱水やカリウム変動に注意します。")]
    case "糖尿病治療薬", "インスリン製剤":
        return [("🍬", "低血糖", "冷汗・ふるえ・動悸が出たらすぐに対処します。"), ("🚻", "頻尿・脱水", "SGLT2阻害薬では水分補給が大切です。")]
    case "抗菌薬", "抗ウイルス薬":
        return [("🤢", "胃腸症状", "吐き気や下痢がみられることがあります。"), ("🌡️", "発疹", "アレルギー症状が出たら中止して相談してください。")]
    case "抗ヒスタミン薬", "抗不安薬", "睡眠薬":
        return [("😴", "眠気", "車の運転や高所作業は注意が必要です。"), ("🌀", "ふらつき", "高齢者では転倒に注意してください。")]
    case "輸液用電解質液":
        return [("💧", "むくみ・過量投与", "点滴量が多いと浮腫、肺水腫、呼吸苦につながることがあります。"), ("⚡️", "電解質変動", "ナトリウムやカリウム、血糖の変動に注意します。")]
    case "注射用抗菌薬":
        return [("🌡️", "発疹・アレルギー", "皮疹やアナフィラキシーに注意します。"), ("🤢", "下痢", "抗菌薬関連下痢や偽膜性大腸炎に注意します。")]
    case "麻酔・鎮静薬":
        return [("🫁", "呼吸抑制", "呼吸が浅くなることがあり、監視下で使用します。"), ("🩺", "血圧低下", "循環抑制や徐脈に注意します。")]
    case "救急循環作動薬":
        return [("🫀", "動悸・不整脈", "心拍数増加や不整脈に注意します。"), ("📈", "血圧上昇", "過度の昇圧や末梢虚血に注意します。")]
    case let category where isInjectionCategory(category):
        return [("⚠️", "過敏症", "発疹、かゆみ、呼吸苦などのアレルギー症状に注意します。"), ("💉", "注射部位反応", "疼痛、発赤、腫脹、血管痛が出ることがあります。")]
    default:
        return [("⚠️", "一般的な副作用", "症状に応じて医師・薬剤師へ相談してください。")]
    }
}

private func adverseEffects(for category: String) -> [(name: String, freq: String, detail: String)] {
    switch category {
    case "解熱鎮痛薬", "解熱鎮痛消炎剤", "鎮痛薬":
        return [
            ("胃部不快感・胃痛", "記載あり", "消化器症状として悪心、胃痛、胃部不快感、食欲不振などがみられることがあります。"),
            ("消化性潰瘍・消化管出血", "重大", "黒色便、吐血、強い腹痛がある場合は投与中止を含めて速やかに対応します。"),
            ("腎機能障害", "重大", "尿量低下、浮腫、血清クレアチニン上昇に注意します。脱水や高齢者では特に注意が必要です。"),
            ("発疹・そう痒", "記載あり", "皮疹、かゆみ、蕁麻疹などの過敏症状が出ることがあります。")
        ]
    case "鎮痛補助薬":
        return [
            ("傾眠", "記載あり", "眠気が出ることがあります。運転や危険作業は避けるよう説明します。"),
            ("浮動性めまい", "記載あり", "ふらつきやめまいにより転倒リスクが上がることがあります。"),
            ("浮腫", "記載あり", "下腿浮腫、体重増加がみられることがあります。"),
            ("体重増加", "記載あり", "長期使用時に体重増加がみられることがあります。")
        ]
    case "カルシウム拮抗薬":
        return [
            ("浮腫", "記載あり", "下腿・足首のむくみがみられることがあります。"),
            ("頭痛・ほてり", "記載あり", "血管拡張に伴い頭痛、顔面紅潮、ほてりが出ることがあります。"),
            ("動悸", "記載あり", "頻脈感や動悸が出ることがあります。"),
            ("歯肉肥厚", "頻度不明", "長期使用時に歯肉腫脹がみられることがあります。")
        ]
    case "ARB", "ACE阻害薬":
        return [
            ("血圧低下", "記載あり", "めまい、立ちくらみ、ふらつきに注意します。"),
            ("腎機能障害", "重大", "血清クレアチニン上昇、尿量低下に注意します。"),
            ("高カリウム血症", "重大", "脱力感、不整脈、しびれが出ることがあります。腎機能低下例では特に注意します。"),
            ("咳嗽", category == "ACE阻害薬" ? "記載あり" : "頻度低い", "ACE阻害薬では乾性咳嗽が問題になることがあります。")
        ]
    case "β遮断薬":
        return [
            ("徐脈", "記載あり", "脈拍低下、めまい、失神に注意します。"),
            ("倦怠感", "記載あり", "だるさ、疲れやすさが出ることがあります。"),
            ("心不全悪化", "重大", "息切れ、浮腫、急な体重増加に注意します。"),
            ("気管支けいれん", "頻度不明", "喘息・COPD患者では息苦しさや喘鳴に注意します。")
        ]
    case "利尿薬":
        return [
            ("低カリウム血症", "記載あり", "脱力感、筋けいれん、不整脈に注意します。"),
            ("低ナトリウム血症", "記載あり", "倦怠感、意識障害、ふらつきに注意します。"),
            ("高尿酸血症", "記載あり", "痛風発作や尿酸値上昇に注意します。"),
            ("脱水", "記載あり", "口渇、立ちくらみ、腎機能悪化に注意します。")
        ]
    case "脂質異常症治療薬":
        return [
            ("筋肉痛・脱力感", "記載あり", "横紋筋融解症の初期症状として注意します。"),
            ("横紋筋融解症", "重大", "筋痛、褐色尿、CK上昇があれば速やかに対応します。"),
            ("肝機能障害", "記載あり", "AST、ALT上昇や倦怠感、黄疸に注意します。"),
            ("消化器症状", "記載あり", "腹部不快感、便秘、下痢などがみられることがあります。")
        ]
    case "抗凝固薬", "抗血小板薬":
        return [
            ("出血", "重大", "鼻出血、歯肉出血、血尿、黒色便、皮下出血に注意します。"),
            ("貧血", "記載あり", "出血に伴うふらつき、息切れ、Hb低下に注意します。"),
            ("消化管出血", "重大", "黒色便、吐血、腹痛がある場合は速やかに対応します。"),
            ("発疹", "記載あり", "薬疹や過敏症状が出ることがあります。")
        ]
    case "糖尿病治療薬", "インスリン製剤":
        return [
            ("低血糖", "重大", "冷汗、ふるえ、動悸、強い空腹感、意識障害に注意します。"),
            ("消化器症状", "記載あり", "悪心、下痢、腹部不快感がみられることがあります。"),
            ("脱水", "記載あり", "SGLT2阻害薬では口渇、頻尿、脱水に注意します。"),
            ("尿路・性器感染", "記載あり", "SGLT2阻害薬では排尿痛、かゆみ、発熱に注意します。")
        ]
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return [
            ("下痢・軟便", "記載あり", "腸内環境変化により下痢や軟便がみられることがあります。"),
            ("便秘", "記載あり", "便通変化がみられることがあります。"),
            ("肝機能障害", "頻度不明", "AST、ALT上昇や倦怠感、黄疸に注意します。"),
            ("発疹", "記載あり", "皮疹、かゆみなどの過敏症状が出ることがあります。")
        ]
    case "整腸剤":
        return [
            ("腹部膨満感", "記載あり", "お腹の張りがみられることがあります。"),
            ("便秘", "記載あり", "便通が変化することがあります。"),
            ("下痢", "記載あり", "軟便や下痢がみられることがあります。"),
            ("発疹", "頻度不明", "過敏症状として皮疹が出ることがあります。")
        ]
    case "止瀉薬", "下剤", "消化管運動改善薬", "胃粘膜保護薬", "制吐薬":
        return [
            ("腹痛", "記載あり", "腹部不快感や腹痛がみられることがあります。"),
            ("下痢", "記載あり", "便通がゆるくなることがあります。"),
            ("便秘", "記載あり", "薬効や体質により便秘がみられることがあります。"),
            ("悪心", "記載あり", "吐き気や胃部不快感が出ることがあります。")
        ]
    case "抗菌薬", "抗ウイルス薬":
        return [
            ("下痢", "記載あり", "腸内細菌叢の変化により下痢がみられることがあります。"),
            ("悪心・嘔吐", "記載あり", "消化器症状として吐き気や嘔吐が出ることがあります。"),
            ("発疹", "記載あり", "薬疹や過敏症状が出ることがあります。"),
            ("肝機能障害", "頻度不明", "AST、ALT上昇や黄疸に注意します。")
        ]
    case "抗ヒスタミン薬":
        return [
            ("眠気", "記載あり", "日中の眠気、集中力低下に注意します。"),
            ("口渇", "記載あり", "口の渇きがみられることがあります。"),
            ("倦怠感", "記載あり", "だるさや疲労感が出ることがあります。"),
            ("めまい", "記載あり", "ふらつきや転倒に注意します。")
        ]
    case "抗喘息薬", "気管支拡張薬", "吸入配合剤":
        return [
            ("動悸", "記載あり", "β2刺激薬では動悸や頻脈が出ることがあります。"),
            ("振戦", "記載あり", "手のふるえがみられることがあります。"),
            ("口腔カンジダ", "記載あり", "吸入ステロイド使用後はうがいが重要です。"),
            ("嗄声", "記載あり", "声がれがみられることがあります。")
        ]
    case "去痰薬", "鎮咳薬":
        return [
            ("悪心", "記載あり", "吐き気や胃部不快感が出ることがあります。"),
            ("食欲不振", "記載あり", "食欲低下がみられることがあります。"),
            ("発疹", "頻度不明", "皮疹やかゆみが出ることがあります。"),
            ("眠気", "記載あり", "鎮咳薬では眠気が出ることがあります。")
        ]
    case "抗不安薬", "睡眠薬":
        return [
            ("眠気", "記載あり", "翌朝への持ち越し、日中の眠気に注意します。"),
            ("ふらつき", "記載あり", "転倒や骨折リスクに注意します。"),
            ("健忘", "記載あり", "服用後の記憶があいまいになることがあります。"),
            ("依存性", "重大", "長期使用や急な中止で離脱症状が出ることがあります。")
        ]
    case "抗うつ薬":
        return [
            ("悪心", "記載あり", "開始初期に吐き気や胃部不快感がみられることがあります。"),
            ("眠気・不眠", "記載あり", "眠気または不眠が出ることがあります。"),
            ("口渇", "記載あり", "口の渇きがみられることがあります。"),
            ("セロトニン症候群", "重大", "発熱、発汗、振戦、焦燥、意識変容に注意します。")
        ]
    case "抗精神病薬":
        return [
            ("錐体外路症状", "記載あり", "手のふるえ、筋強剛、アカシジアなどに注意します。"),
            ("眠気", "記載あり", "日中の眠気や活動性低下に注意します。"),
            ("高血糖", "重大", "口渇、多飲、多尿、血糖上昇に注意します。"),
            ("悪性症候群", "重大", "発熱、筋強剛、意識障害、自律神経症状に注意します。")
        ]
    case "排尿障害治療薬":
        return [
            ("めまい・立ちくらみ", "記載あり", "α1遮断薬では起立性低血圧に注意します。"),
            ("口渇", "記載あり", "抗コリン薬では口の渇きがみられることがあります。"),
            ("便秘", "記載あり", "抗コリン薬では便秘がみられることがあります。"),
            ("排尿困難", "頻度不明", "尿閉や排尿しにくさに注意します。")
        ]
    case "骨粗鬆症治療薬":
        return [
            ("胃部不快感", "記載あり", "ビスホスホネートでは食道刺激や胃部不快感に注意します。"),
            ("顎骨壊死", "重大", "抜歯予定や口腔内感染がある場合は事前確認が必要です。"),
            ("低カルシウム血症", "重大", "しびれ、筋けいれん、テタニーに注意します。"),
            ("筋骨格痛", "記載あり", "関節痛、筋肉痛、骨痛がみられることがあります。")
        ]
    case "甲状腺治療薬":
        return [
            ("発疹", "記載あり", "皮疹やかゆみがみられることがあります。"),
            ("肝機能障害", "重大", "倦怠感、黄疸、AST/ALT上昇に注意します。"),
            ("無顆粒球症", "重大", "発熱、咽頭痛が出た場合は速やかに受診が必要です。"),
            ("動悸", "記載あり", "補充量過多では動悸や頻脈に注意します。")
        ]
    case "痛風治療薬":
        return [
            ("発疹", "記載あり", "皮疹やかゆみなどの過敏症状に注意します。"),
            ("肝機能障害", "記載あり", "AST、ALT上昇や黄疸に注意します。"),
            ("痛風発作", "記載あり", "尿酸値変動により開始初期に発作が起こることがあります。"),
            ("消化器症状", "記載あり", "悪心、下痢、腹部不快感がみられることがあります。")
        ]
    case "漢方製剤":
        return [
            ("偽アルドステロン症", "重大", "むくみ、血圧上昇、低カリウム血症、脱力感に注意します。甘草含有製剤で重要です。"),
            ("間質性肺炎", "重大", "発熱、咳、息切れが出た場合は速やかに相談が必要です。"),
            ("肝機能障害", "重大", "倦怠感、黄疸、AST/ALT上昇に注意します。"),
            ("胃部不快感", "記載あり", "食欲不振、胃もたれ、悪心が出ることがあります。")
        ]
    case "点眼薬":
        return [
            ("眼刺激感", "記載あり", "しみる感じ、異物感、眼痛がみられることがあります。"),
            ("結膜充血", "記載あり", "充血やかゆみが出ることがあります。"),
            ("眼瞼炎", "頻度不明", "まぶたの腫れ、発赤、かゆみに注意します。"),
            ("角膜障害", "重大", "眼痛、見えにくさ、強い充血があれば相談してください。")
        ]
    case "外用薬":
        return [
            ("皮膚刺激感", "記載あり", "ひりつき、灼熱感、刺激感がみられることがあります。"),
            ("発赤", "記載あり", "塗布部位の赤みが出ることがあります。"),
            ("そう痒", "記載あり", "かゆみが出ることがあります。"),
            ("接触皮膚炎", "頻度不明", "かぶれ、湿疹、腫れが出た場合は中止を含めて相談します。")
        ]
    case "輸液用電解質液":
        return [
            ("脳浮腫・肺水腫・末梢浮腫", "頻度不明", "過量投与や水分貯留により、頭痛、意識変容、呼吸苦、むくみがあらわれることがあります。"),
            ("水中毒", "頻度不明", "低ナトリウム血症を伴う倦怠感、悪心、頭痛、けいれん、意識障害に注意します。"),
            ("高カリウム血症", "頻度不明", "T3系などカリウムを含む製剤では、腎機能低下や乏尿がある場合に脱力、不整脈、しびれに注意します。"),
            ("血糖上昇", "頻度不明", "ブドウ糖を含むため、糖尿病や耐糖能異常では血糖変動を確認します。")
        ]
    default:
        return [
            ("発疹", "記載あり", "皮疹やかゆみなどの過敏症状が出ることがあります。"),
            ("消化器症状", "記載あり", "悪心、下痢、腹部不快感がみられることがあります。"),
            ("めまい", "記載あり", "ふらつきや転倒に注意します。"),
            ("肝機能障害", "頻度不明", "倦怠感、黄疸、AST/ALT上昇に注意します。")
        ]
    }
}

private func interactionWarning(for seed: MedicineSeed) -> String {
    switch seed.category {
    case "抗凝固薬", "抗血小板薬":
        return "\(seed.brandName)は出血を増やす薬やサプリメントと併用時に注意が必要です。抜歯・内視鏡・手術予定がある場合は、必ず事前に申告してください。"
    case "抗不安薬", "睡眠薬", "抗ヒスタミン薬":
        return "\(seed.brandName)はアルコールや眠気を強める薬と併用すると、眠気・ふらつき・判断力低下が強く出ることがあります。"
    case "糖尿病治療薬", "インスリン製剤":
        return "\(seed.brandName)は食事量、運動量、他の糖尿病薬との組み合わせによって低血糖や脱水のリスクが変わるため、体調不良時は自己判断で続けず相談が必要です。"
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return "\(seed.brandName)は併用薬によっては吸収や効果に影響することがあります。抗血小板薬や長期服用中の薬がある場合は申告してください。"
    case "輸液用電解質液":
        return "\(seed.brandName)は水分・電解質・糖質を点滴で補う薬です。腎機能障害、心不全、乏尿、高カリウム血症、糖尿病では投与量や電解質・血糖の確認が重要です。"
    default:
        return "\(seed.brandName)を使用中は、他院処方・市販薬・サプリメントを含めて併用薬を必ず申告してください。"
    }
}

private func howToTake(for seed: MedicineSeed) -> String {
    switch seed.category {
    case "プロトンポンプ阻害薬（PPI）", "P-CAB":
        return "\(seed.brandName)は食前や指示されたタイミングで飲むと効果が安定しやすい薬です。症状が落ち着いても自己判断で中断せず、指示期間を守ってください。"
    case "睡眠薬":
        return "\(seed.brandName)は就寝直前に服用し、服用後はスマホ操作や運転などを避けてそのまま休むのが基本です。"
    case "抗ヒスタミン薬":
        return "\(seed.brandName)は眠気が出ることがあるため、初回は予定に余裕のある日に試すと安心です。花粉症や蕁麻疹では継続して使うことで安定しやすいです。"
    case "糖尿病治療薬":
        return "\(seed.brandName)は毎日同じタイミングで飲むと効果を評価しやすくなります。食事量が極端に少ない日や体調不良時の対応は事前に確認しておくと安心です。"
    case "インスリン製剤":
        return "\(seed.brandName)は自己注射の手技、打つ時間、単位数の確認が重要です。注射忘れや低血糖時の対応をあらかじめ理解しておいてください。"
    case "点眼薬":
        return "\(seed.brandName)は決められた回数・滴数で点眼します。容器の先端がまぶたやまつ毛に触れないようにし、点眼後はしばらく目を閉じて薬液をなじませてください。"
    case "外用薬":
        return "\(seed.brandName)は患部に直接使用する薬です。塗る量や回数は指示に従い、傷やただれの有無、手洗いの要否、密封の指示があるかを確認して使ってください。"
    case "吸入配合剤", "気管支拡張薬":
        return "\(seed.brandName)は吸入手技が効果に直結します。息を十分に吐いてから吸入し、使用後にうがいが必要な製剤では忘れずに行ってください。"
    case "輸液用電解質液":
        return "\(seed.brandName)は医療機関で点滴静注する輸液です。投与中は点滴速度、尿量、むくみ、息苦しさ、血糖や電解質の変化を確認しながら調整します。"
    case let category where isInjectionCategory(category):
        return "\(seed.brandName)は医療機関で静脈内・筋肉内などに投与する注射薬です。投与量、投与速度、投与経路を確認しながら使用し、投与中後は血圧・脈拍・呼吸状態やアレルギー症状の有無を観察します。"
    default:
        return "\(seed.brandName)は処方された回数と時間帯を守って使用してください。自己判断で中止・増量せず、症状や副作用の変化があれば相談することが大切です。"
    }
}

private func usageDescription(for seed: MedicineSeed) -> String {
    let tags = seed.tags.prefix(3).joined(separator: "、")
    switch seed.category {
    case "糖尿病治療薬":
        return "\(seed.brandName)は血糖コントロールを改善する\(seed.category)で、\(tags)の観点から選択されることが多い薬です。"
    case "ARB", "ACE阻害薬", "β遮断薬", "利尿薬", "カルシウム拮抗薬":
        return "\(seed.brandName)は\(seed.category)に分類され、高血圧や循環器疾患の管理で使われる代表的な薬です。"
    case "抗凝固薬", "抗血小板薬":
        return "\(seed.brandName)は血栓予防を目的に用いられる\(seed.category)で、\(tags)といった場面で重要になる薬です。"
    case "抗菌薬", "抗ウイルス薬":
        return "\(seed.brandName)は感染症治療で使われる\(seed.category)です。想定される原因微生物や重症度に応じて選択されます。"
    case "抗ヒスタミン薬":
        return "\(seed.brandName)は\(seed.category)で、\(tags)などのアレルギー症状を抑える目的で使われます。"
    case "プロトンポンプ阻害薬（PPI）", "P-CAB", "H2受容体拮抗薬":
        return "\(seed.brandName)は胃酸分泌を抑える\(seed.category)で、\(tags)の改善に使われることが多い薬です。"
    case "点眼薬":
        return "\(seed.brandName)は\(seed.category)として、\(tags)に対して局所的に作用する薬です。"
    case "外用薬":
        return "\(seed.brandName)は皮膚に直接使う\(seed.category)で、\(tags)に関連する症状の改善を目的に用います。"
    case "吸入配合剤", "気管支拡張薬":
        return "\(seed.brandName)は吸入で気道に作用する\(seed.category)で、\(tags)などの呼吸器症状を和らげる目的で使われます。"
    case "輸液用電解質液":
        return "\(seed.brandName)は点滴で水分・電解質を補う輸液で、\(tags)などの目的で医療機関で使用されます。"
    case let category where isInjectionCategory(category):
        return "\(seed.brandName)は\(seed.category)に分類される注射薬で、\(tags)などの場面で医療機関で使用されます。"
    default:
        return "\(seed.brandName)は\(seed.category)に分類される薬で、\(tags)といった用途で使われることが多い薬です。"
    }
}

private func whatIsIt(for seed: MedicineSeed) -> String {
    "\(usageDescription(for: seed)) 一般名は\(seed.genericName)で、\(seed.maker)の製品として処方や説明で目にすることの多い薬です。販売名と一般名の違い、主な用途が分かるように整理しています。"
}

private func qa(for seed: MedicineSeed) -> [(q: String, a: String)] {
    let missedUseQuestion: String
    if seed.category == "点眼薬" || seed.category == "外用薬" || seed.category == "吸入配合剤" || seed.category == "気管支拡張薬" {
        missedUseQuestion = "使い忘れたら？"
    } else if seed.category == "輸液用電解質液" || isInjectionCategory(seed.category) {
        missedUseQuestion = "予定どおり使えなかったら？"
    } else {
        missedUseQuestion = "飲み忘れたら？"
    }

    return [
        (missedUseQuestion, "気づいた時点で自己判断せず、次回の使用タイミングや追加の要否を医師・薬剤師の指示に従って確認してください。2回分をまとめて使わないことが基本です。"),
        ("この薬の詳しい情報は？", "この画面は要点をまとめた解説です。適応追加や最新の安全性情報はPMDAや添付文書で確認してください。")
    ]
}

private func genericProducts(for seed: MedicineSeed) -> [(name: String, price: Double, maker: String)] {
    guard seed.rx,
          !seed.brandName.contains("「"),
          !["漢方製剤", "ワクチン", "インスリン製剤", "輸液用電解質液"].contains(seed.category) else {
        return []
    }

    let baseName = genericProductBaseName(for: seed)
    let suffixes: [(suffix: String, maker: String)] = [
        ("サワイ", "沢井製薬"),
        ("トーワ", "東和薬品"),
        ("日医工", "日医工"),
        ("ニプロ", "ニプロ"),
        ("JG", "日本ジェネリック")
    ]

    return suffixes.map { item in
        (
            name: "\(baseName)「\(item.suffix)」",
            price: 0,
            maker: item.maker
        )
    }
}

private func genericProductBaseName(for seed: MedicineSeed) -> String {
    let normalized = seed.genericName
        .replacingOccurrences(of: "水和物", with: "")
        .replacingOccurrences(of: "塩酸塩", with: "")
        .replacingOccurrences(of: "硫酸塩", with: "")
        .replacingOccurrences(of: "リン酸塩", with: "")
        .replacingOccurrences(of: "臭化水素酸塩", with: "")
        .replacingOccurrences(of: "メタンスルホン酸塩", with: "")
        .replacingOccurrences(of: "マレイン酸塩", with: "")
        .replacingOccurrences(of: "フマル酸塩", with: "")
        .replacingOccurrences(of: "ナトリウム", with: "Na")
        .replacingOccurrences(of: "カリウム", with: "K")

    if normalized.contains("錠") || normalized.contains("カプセル") || normalized.contains("OD") || normalized.contains("散") {
        return normalized
    }

    switch seed.category {
    case "点眼薬":
        return "\(normalized)点眼液"
    case "外用薬":
        return "\(normalized)外用"
    case "吸入薬", "吸入配合剤":
        return "\(normalized)吸入"
    default:
        return "\(normalized)錠"
    }
}

// MARK: - ネットでの話題・備考（参考情報）
// SNS・ニュース・健康系メディアなどで広く取り上げられている内容の要約。
// 該当する話題がない薬は空のままにする（詳細画面でセクション非表示になる）。
private let webTopicsByBrand: [String: [String]] = [
    "カロナール": [
        "コロナ禍の発熱外来需要で出荷調整となり、ニュースで大きく報道された",
        "子どもや妊婦にも使いやすい解熱鎮痛薬として健康系メディアで紹介されることが多い",
        "ロキソニンとの効き方・胃へのやさしさの違いが頻繁に検索されている"
    ],
    "ブルフェン": [
        "市販の「イブ」シリーズなどと同じイブプロフェンが成分で、比較記事でよく登場する"
    ],
    "ボルタレン": [
        "貼り薬・塗り薬の「ボルタレンEX」シリーズが市販されており知名度が高い",
        "NSAIDsの中でも効き目が強い分、胃への負担に注意という解説が定番"
    ],
    "リリカ": [
        "神経の痛み（しびれ）の薬として処方が多く、眠気・ふらつきの体験談がQ&Aサイトで目立つ",
        "ジェネリック（プレガバリン）の発売で薬代が下がったことが話題になった",
        "服用中の自動車運転に注意が必要という情報がよく共有される"
    ],
    "アダラート": [
        "グレープフルーツとの飲み合わせに注意が必要なカルシウム拮抗薬として紹介される"
    ],
    "ディオバン": [
        "過去に臨床研究データ問題が大きく報道されたが、薬自体の有効性・安全性は確認されている"
    ],
    "ワーファリン": [
        "「納豆・クロレラ・青汁NG」の代表的な薬としてテレビ・ネットで繰り返し紹介される",
        "新しい抗凝固薬（DOAC）との違い・切り替えの記事が多い",
        "定期的な血液検査（PT-INR）が必要なことが解説記事の定番ポイント"
    ],
    "エリキュース": [
        "心房細動の脳梗塞予防で処方が増えているDOACとして医療メディアで紹介される",
        "ワーファリンと違い食事制限がほぼ不要な点がよく取り上げられる"
    ],
    "イグザレルト": [
        "1日1回タイプのDOACとして紹介され、飲み忘れ時の対応がよく検索される"
    ],
    "バイアスピリン": [
        "低用量アスピリンの「予防のための服用」の是非が健康記事でたびたび議論される",
        "手術や内視鏡検査の前に休薬が必要かどうかの解説が多い"
    ],
    "メトグルコ": [
        "糖尿病治療の世界的な第一選択薬として健康系メディアで頻繁に紹介される",
        "造影剤を使う検査の前後で休薬が必要なことが注意喚起される",
        "まれな副作用「乳酸アシドーシス」とシックデイ（体調不良時の休薬）の解説が定番"
    ],
    "ジャディアンス": [
        "糖尿病だけでなく心不全・慢性腎臓病への適応拡大がニュースで報道された",
        "尿に糖を出す仕組みのため、尿路・性器感染症への注意がよく取り上げられる"
    ],
    "フォシーガ": [
        "心不全・慢性腎臓病にも使えるSGLT2阻害薬として報道が多い",
        "「痩せる薬」としての自己判断使用への注意喚起が繰り返されている"
    ],
    "サイレース": [
        "持ち出し・悪用対策として錠剤が青く着色されていることが知られている",
        "ベンゾジアゼピン系睡眠薬の依存・減薬の話題でよく名前が挙がる"
    ],
    "デパケン": [
        "妊娠可能な女性への処方に注意が必要な薬として医療記事で取り上げられる"
    ],
    "リーマス": [
        "血中濃度の定期測定が必要な薬の代表例として解説されることが多い",
        "脱水や鎮痛薬（NSAIDs）併用でリチウム中毒のリスクが上がる点が注意喚起される"
    ],
    "プレドニン": [
        "ステロイドの代表薬として「やめ方（漸減）」や「ムーンフェイス」の話題が多い",
        "自己判断での急な中止が危険なことが繰り返し注意喚起されている"
    ],
    "ロコイド軟膏": [
        "比較的マイルドなステロイド外用薬として子どもの湿疹の話題でよく登場する",
        "ステロイド外用薬の強さランクの解説記事で頻繁に引用される"
    ],
    "ディフェリンゲル": [
        "ニキビ治療の定番外用薬として美容系メディア・SNSで話題が多い",
        "使い始めの乾燥・ヒリつき（A反応）の体験談がよく共有される"
    ],
    "ベピオゲル": [
        "市販化されていないニキビ治療薬として皮膚科受診を勧める記事で紹介される",
        "漂白作用があり衣類やタオルの色落ちに注意という情報が定番"
    ],
    "モビコール": [
        "子どもの便秘治療の新定番として育児系メディアで取り上げられることが多い",
        "水に溶かして飲む薬で、味の工夫（ジュースに混ぜる等）の体験談が人気"
    ],
    "ムコスタ": [
        "NSAIDsと一緒に処方される「胃薬」の定番としてよく紹介される"
    ],
    "タリオン": [
        "眠くなりにくく効き目とのバランスが良い花粉症薬として比較記事に登場する",
        "市販薬（タリオンAR・R）としても購入できるようになったことが話題になった"
    ],
    "フルナーゼ": [
        "市販の点鼻薬（フルナーゼ点鼻薬）としても買えることが花粉症記事で紹介される"
    ],
    "ナゾネックス": [
        "1日1回タイプのステロイド点鼻薬として花粉症シーズンに検索が増える"
    ],
    "トランサミン": [
        "本来は止血・のどの薬だが「シミ・肝斑ケア」としての話題が美容系メディアで多い"
    ],
    "クレストール": [
        "効き目の強い「ストロングスタチン」として比較記事でよく登場する",
        "筋肉痛・横紋筋融解症の初期症状に関する注意喚起が定番"
    ],
    "リピトール": [
        "世界で最も売れた薬のひとつとして紹介されることが多いスタチン",
        "グレープフルーツジュースとの相互作用に注意という記事が多い"
    ],
    "エパデール": [
        "魚の油（EPA）由来の薬として健康系メディアで取り上げられる",
        "市販版（エパデールT）が薬局で買えることが紹介されることもある"
    ],
    "アジルバ": [
        "ARBの中でも降圧効果が強いと比較記事で取り上げられることが多い",
        "ジェネリック発売のニュースが医療系メディアで話題になった"
    ],
    "プラビックス": [
        "胃薬（PPI）の一部と相性が悪く効果が弱まる場合があることが解説記事で言及される",
        "心臓ステント治療後の「2剤併用（DAPT）」の話題でよく登場する"
    ],
    "プレタール": [
        "頭痛・動悸の副作用と「脈が速くなる」体験談がQ&Aサイトで目立つ"
    ],
    "ラシックス": [
        "「むくみ取り」目的の不適切な自己使用への注意喚起がたびたび話題になる"
    ],
    "サムスカ": [
        "水だけを出す新しいタイプの利尿薬として医療メディアで紹介される",
        "急激なナトリウム上昇を避けるため入院して開始する薬として知られる"
    ],
    "ジャヌビア": [
        "DPP-4阻害薬の代表として糖尿病解説記事に頻出する"
    ],
    "タミフル": [
        "インフルエンザ流行期に毎年ニュース・SNSで話題になる"
    ],
    "ジルテック": [
        "同成分の市販薬が複数あり、処方薬と市販薬の比較記事でよく登場する"
    ],
    "アンカロン": [
        "甲状腺・肺・眼など定期検査が必要な抗不整脈薬として医療記事で解説される"
    ],
    "ジゴシン": [
        "血中濃度管理（TDM）が必要な古典的な強心薬として薬学系記事に登場する"
    ],
    "リスパダール内用液": [
        "液体タイプで飲みやすい一方、お茶・コーラ類と混ぜると効果が落ちることが注意喚起される"
    ]
]

private func webTopics(for seed: MedicineSeed) -> [String] {
    webTopicsByBrand[seed.brandName] ?? []
}

private let expandedMedicineSeeds = additionalMedicineSeeds + supplementalMedicineSeeds

let additionalMedicines: [Medicine] = expandedMedicineSeeds.enumerated().map { offset, seed in
    Medicine.lite(
        id: 1000 + offset,
        name: seed.genericName,
        kana: seed.kana,
        genericName: seed.genericName,
        brandName: seed.brandName,
        category: seed.category,
        maker: seed.maker,
        tags: seed.tags,
        webTopics: webTopics(for: seed),
        rx: seed.rx,
        makerURLString: Medicine.manufacturerURL(for: seed.maker),
        brandPrice: seed.brandPrice,
        brandPriceName: seed.brandName,
        generics: genericProducts(for: seed),
        unit: unit(for: seed.category),
        mechanism: mechanism(for: seed.category),
        actionSummary: actionSummary(for: seed.category),
        indications: indications(for: seed),
        dosage: dosage(for: seed.category),
        dosageNotes: dosageNotes(for: seed.category),
        adverseEffects: adverseEffects(for: seed.category),
        monitoring: monitoring(for: seed.category),
        whatIsIt: whatIsIt(for: seed),
        howToTake: howToTake(for: seed),
        sideEffects: sideEffects(for: seed.category),
        dailyLife: [
            "自己判断で中止・増量しない",
            "他院・市販薬・サプリの併用は申告する"
        ] + seed.tags.prefix(2),
        interactionWarning: interactionWarning(for: seed),
        qa: qa(for: seed)
    )
}

let allMedicines: [Medicine] = (baseMedicines + additionalMedicines)
    .sorted { lhs, rhs in
        if lhs.brandName == rhs.brandName {
            return lhs.name < rhs.name
        }
        return lhs.brandName < rhs.brandName
    }
