import SwiftUI

struct MedicineDetailView: View {
    @EnvironmentObject var appState: AppState
    let medicine: Medicine
    @State private var proMode: Bool = false
    @State private var displayedMedicine: Medicine? = nil
    @State private var remoteLoading = false
    @Environment(\.dismiss) var dismiss

    var currentMedicine: Medicine { displayedMedicine ?? medicine }
    var isFav: Bool { appState.favMedicines.contains(currentMedicine.id) }

    var body: some View {
        NavigationStack {
            ZStack {
                DetailScreenBackground(proMode: proMode)

                ScrollView {
                    VStack(spacing: 14) {
                        HeroCard(medicine: currentMedicine, isFav: isFav)

                        ProModeToggle(isOn: $proMode)
                            .padding(.horizontal)

                        if proMode {
                            Label("医療従事者モード", systemImage: "cross.case.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appIndigo)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.92))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.appIndigo.opacity(0.18), lineWidth: 1)
                                )
                        }

                        if remoteLoading {
                            ProgressView("公開データベースの情報を反映中...")
                                .font(.caption)
                        }

                        if proMode {
                            ProDetailView(medicine: currentMedicine)
                        } else {
                            GeneralDetailView(medicine: currentMedicine)
                        }

                        DisclaimerBox().padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(currentMedicine.brandName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.toggleMed(currentMedicine)
                    } label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .foregroundColor(isFav ? .appPink : .primary)
                    }
                }
            }
        }
        .task {
            proMode = appState.proMode
            await enrichFromPMDAIfPossible()
        }
    }

    func enrichFromPMDAIfPossible() async {
        if let cached = MedicineRepository.shared.importedMedicine(for: medicine.id) {
            displayedMedicine = cached
            return
        }

        remoteLoading = true
        defer { remoteLoading = false }
        do {
            let enriched = try await PMDAService.enrich(medicine)
            MedicineRepository.shared.upsert(enriched)
            displayedMedicine = enriched
        } catch {
            displayedMedicine = nil
        }
    }
}

// MARK: - HeroCard
private struct HeroCard: View {
    let medicine: Medicine
    let isFav: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let photoURL = medicine.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        ZoomableMedicineImage(image: image)
                    case .failure:
                        EmptyView()
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    }
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.brandName)
                        .font(.title2).fontWeight(.bold)
                    Text(medicine.name)
                        .font(.caption).foregroundColor(.appTextSecondary)
                    Text(medicine.genericName)
                        .font(.caption2).foregroundColor(.appTextSecondary)
                    if let makerURL = medicine.makerURL {
                        Link(destination: makerURL) {
                            HStack(spacing: 4) {
                                Text(medicine.maker)
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.caption2)
                            .foregroundColor(.appBlue)
                        }
                    } else {
                        Text(medicine.maker)
                            .font(.caption2).foregroundColor(.appTextSecondary)
                    }
                    if let packageInsertURL = medicine.packageInsertURL {
                        Link(destination: packageInsertURL) {
                            HStack(spacing: 4) {
                                Text("添付文書原文PDF")
                                Image(systemName: "doc.richtext")
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.appIndigo)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    RxBadge(rx: medicine.rx)
                    if isFav {
                        Label("お気に入り", systemImage: "heart.fill")
                            .font(.caption2).foregroundColor(.appPink)
                    }
                }
            }
            FlowLayout(spacing: 5) {
                ForEach(medicine.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2).foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isFav ? Color.appPink : Color.clear, lineWidth: 1.5))
        .padding(.horizontal)
    }
}

private struct ZoomableMedicineImage: View {
    let image: Image

    @State private var settledScale: CGFloat = 1
    @State private var settledOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var dragOffset: CGSize = .zero

    private var effectiveScale: CGFloat {
        min(max(settledScale * gestureScale, 1), 4)
    }

    private var effectiveOffset: CGSize {
        let proposed = CGSize(
            width: settledOffset.width + dragOffset.width,
            height: settledOffset.height + dragOffset.height
        )
        return clampedOffset(for: proposed, scale: effectiveScale)
    }

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .scaleEffect(effectiveScale)
            .offset(effectiveOffset)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .gesture(combinedGesture)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    if settledScale > 1 {
                        settledScale = 1
                        settledOffset = .zero
                    } else {
                        settledScale = 2
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if settledScale > 1.01 || gestureScale > 1.01 {
                    Text(String(format: "%.1fx", effectiveScale))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(10)
                }
            }
    }

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            MagnifyGesture()
                .updating($gestureScale) { value, state, _ in
                    state = value.magnification
                }
                .onEnded { value in
                    let newScale = min(max(settledScale * value.magnification, 1), 4)
                    settledScale = newScale
                    settledOffset = clampedOffset(for: settledOffset, scale: newScale)
                    if newScale <= 1.01 {
                        settledOffset = .zero
                    }
                },
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    guard effectiveScale > 1.01 else { return }
                    state = value.translation
                }
                .onEnded { value in
                    guard effectiveScale > 1.01 else {
                        settledOffset = .zero
                        return
                    }
                    let proposed = CGSize(
                        width: settledOffset.width + value.translation.width,
                        height: settledOffset.height + value.translation.height
                    )
                    settledOffset = clampedOffset(for: proposed, scale: settledScale)
                }
        )
    }

    private func clampedOffset(for offset: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1 else { return .zero }

        let baseWidth: CGFloat = 320
        let baseHeight: CGFloat = 180
        let horizontalLimit = ((baseWidth * scale) - baseWidth) / 2
        let verticalLimit = ((baseHeight * scale) - baseHeight) / 2

        return CGSize(
            width: min(max(offset.width, -horizontalLimit), horizontalLimit),
            height: min(max(offset.height, -verticalLimit), verticalLimit)
        )
    }
}

// MARK: - ProDetailView
struct ProDetailView: View {
    let medicine: Medicine
    var m: Medicine.ProInfo { medicine.pro }

    var body: some View {
        VStack(spacing: 12) {
            if m.documentSections.isEmpty {
                FixedProDetailSections(medicine: medicine)
            } else {
                FlexibleProDetailSections(medicine: medicine)
            }
        }
    }
}

private struct DetailScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let proMode: Bool

    var body: some View {
        Group {
            if proMode {
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [
                            Color(hex: "11161F"),
                            Color(hex: "151C28"),
                            Color(hex: "101723")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        ZStack {
                            Circle()
                                .fill(Color.appIndigo.opacity(0.16))
                                .frame(width: 260, height: 260)
                                .offset(x: 120, y: -280)
                            Circle()
                                .fill(Color.appTeal.opacity(0.10))
                                .frame(width: 220, height: 220)
                                .offset(x: -130, y: 260)
                        }
                    )
                } else {
                    LinearGradient(
                        colors: [
                            Color.proBackgroundTop,
                            Color.proBackgroundBottom,
                            Color(hex: "F6F9FF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Circle()
                            .fill(Color.appIndigo.opacity(0.08))
                            .frame(width: 260, height: 260)
                            .offset(x: 120, y: -280)
                    )
                }
            } else {
                SoftAppBackground()
            }
        }
        .ignoresSafeArea()
    }
}

private struct FlexibleProDetailSections: View {
    let medicine: Medicine
    var m: Medicine.ProInfo { medicine.pro }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(m.documentSections) { section in
                SectionBox(title: section.title, accentColor: proAccentColor(for: section.title)) {
                    ReadableTextBlock(
                        text: section.body,
                        icon: proIcon(for: section.title),
                        color: proAccentColor(for: section.title)
                    )
                }
                .padding(.horizontal)
            }

            SharedProMetaSections(medicine: medicine)
        }
    }
}

private struct FixedProDetailSections: View {
    let medicine: Medicine
    var m: Medicine.ProInfo { medicine.pro }

    var body: some View {
        VStack(spacing: 12) {
            SectionBox(title: "作用機序", accentColor: .appBlue) {
                ReadableTextBlock(
                    text: m.mechanism,
                    icon: "arrow.triangle.2.circlepath",
                    color: .appBlue,
                    emptyText: "作用機序として表示できる内容を抽出できませんでした。添付文書原文PDFまたは薬効薬理欄を確認してください。",
                    filter: DetailTextFormatter.isMechanismLine(_:)
                )
            }.padding(.horizontal)

            if !m.actionSummary.isEmpty {
                SectionBox(title: "薬理作用・臨床上の位置づけ", accentColor: .appTeal) {
                    ReadableTextBlock(text: m.actionSummary, icon: "cross.case.fill", color: .appTeal)
                }.padding(.horizontal)
            }

            SectionBox(title: "適応症", accentColor: .appBlue) {
                FlowLayout(spacing: 6) {
                    ForEach(m.indications, id: \.self) { ind in
                        Text(ind)
                            .font(.caption).padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.appBlue.opacity(0.12))
                            .foregroundColor(.appBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }.padding(.horizontal)

            SectionBox(title: "用法・用量", accentColor: .appBlue) {
                VStack(alignment: .leading, spacing: 10) {
                    ReadableTextBlock(text: m.dosage, icon: "pills.fill", color: .appBlue)
                    if !m.dosageNotes.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("実務ポイント")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                                .fontWeight(.semibold)
                            ForEach(m.dosageNotes, id: \.self) { note in
                                Label(note, systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.appBlue, Color(.label))
                            }
                        }
                    }
                }
            }.padding(.horizontal)

            if !medicine.interactions.isEmpty {
                SectionBox(title: "薬物相互作用", accentColor: .appRed) {
                    VStack(spacing: 10) {
                        ForEach(medicine.interactions) { di in
                            InteractionRow(interaction: di)
                        }
                    }
                }.padding(.horizontal)
            }

            if !m.adverseEffects.isEmpty {
                SectionBox(title: "副作用", accentColor: .appOrange) {
                    VStack(spacing: 0) {
                        ForEach(DisplayAdverseEffect.filtered(from: m.adverseEffects)) { ae in
                            HStack(alignment: .top, spacing: 10) {
                                Text(ae.frequency)
                                    .font(.caption2).foregroundColor(.appOrange)
                                    .frame(width: 60, alignment: .trailing)
                                    .fontDesign(.monospaced)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ae.name).font(.subheadline).fontWeight(.semibold)
                                    if let detail = ae.detail {
                                        Text(detail).font(.caption).foregroundColor(.appTextSecondary).lineSpacing(3)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            Divider()
                        }
                    }
                }.padding(.horizontal)
            }

            SectionBox(title: "薬物動態", accentColor: .appTeal) {
                VStack(spacing: 0) {
                    ForEach([
                        ("Tmax", m.pk.tmax),
                        ("半減期", m.pk.halfLife),
                        ("蛋白結合率", m.pk.proteinBinding),
                        ("代謝", m.pk.metabolism),
                        ("排泄", m.pk.excretion)
                    ], id: \.0) { key, val in
                        HStack(alignment: .top, spacing: 8) {
                            Text(key).font(.caption).foregroundColor(.appTextSecondary)
                                .frame(width: 70, alignment: .leading).fontWeight(.semibold)
                            Text(val).font(.caption).lineSpacing(3)
                        }
                        .padding(.vertical, 6)
                        Divider()
                    }
                }
            }.padding(.horizontal)

            if !m.contraindications.isEmpty {
                SectionBox(title: "禁忌", accentColor: .appRed) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(m.contraindications, id: \.self) { c in
                            Label(c, systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                                .labelStyle(.titleAndIcon)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.appRed, Color(.label))
                        }
                    }
                }.padding(.horizontal)
            }

            if !m.monitoring.isEmpty {
                SectionBox(title: "モニタリング", accentColor: .appGreen) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(m.monitoring, id: \.self) { mo in
                            Label(mo, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.appGreen, Color(.label))
                        }
                    }
                }.padding(.horizontal)
            }

            if !m.pregnancyCategory.isEmpty {
                SectionBox(title: "妊婦への投与", accentColor: .appPurple) {
                    ReadableTextBlock(text: m.pregnancyCategory, icon: "person.2.fill", color: .appPurple)
                }.padding(.horizontal)
            }

            SharedProMetaSections(medicine: medicine)
        }
    }
}

private struct SharedProMetaSections: View {
    let medicine: Medicine
    var p: Medicine.Pricing { medicine.pricing }

    var body: some View {
        Group {
            SectionBox(title: "製薬メーカー", accentColor: .appIndigo) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(medicine.maker)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let makerURL = medicine.makerURL {
                        Link(destination: makerURL) {
                            Label("メーカー公式ページを開く", systemImage: "building.2.crop.circle")
                                .font(.subheadline)
                        }
                    } else {
                        Text("メーカー公式ページのリンクは未登録です。")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }.padding(.horizontal)

            SectionBox(title: "薬価情報", accentColor: .appIndigo) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("先発品").font(.caption).foregroundColor(.appTextSecondary).fontWeight(.semibold)
                    PriceRow(name: p.brand.name, price: p.brand.price, maker: p.brand.maker,
                             color: .appIndigo, unit: p.unit)
                    Divider()
                    Text("同成分の後発品・ジェネリック").font(.caption).foregroundColor(.appTextSecondary).fontWeight(.semibold)
                    if p.generics.isEmpty {
                        Text("同成分の後発品情報は未取得です。自動取得できた場合はここに表示されます。")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    } else {
                        ForEach(p.generics, id: \.name) { g in
                            PriceRow(name: g.name, price: g.price, maker: g.maker,
                                     color: .appGreen, unit: p.unit)
                        }
                    }
                    if let note = p.note {
                        HStack(alignment: .top, spacing: 6) {
                            Text(note).font(.caption).foregroundColor(.appOrange)
                        }
                        .padding(10).background(Color.appOrange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Divider()
                    Text("💰 \(p.patientBurden30)").font(.caption).foregroundColor(.appTextSecondary)
                    Text("出典: \(p.source)").font(.caption2).foregroundColor(.appTextSecondary)
                }
            }.padding(.horizontal)
        }
    }
}

private struct ReadableTextBlock: View {
    let text: String
    let icon: String
    let color: Color
    var emptyText: String? = nil
    var filter: ((String) -> Bool)? = nil

    private var items: [String] {
        DetailTextFormatter.items(from: text, filter: filter)
    }

    var body: some View {
        if items.isEmpty {
            Text(emptyText ?? text)
                .font(.subheadline)
                .lineSpacing(5)
                .foregroundColor(emptyText == nil ? .primary : .secondary)
        } else if items.count == 1 {
            Text(items[0])
                .font(.subheadline)
                .lineSpacing(5)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Label(item, systemImage: icon)
                        .font(.subheadline)
                        .labelStyle(.titleAndIcon)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(color, Color(.label))
                        .lineLimit(nil)
                }
            }
        }
    }
}

private enum DetailTextFormatter {
    static func items(from text: String, filter: ((String) -> Bool)? = nil) -> [String] {
        let lines = reflowText(text)
            .components(separatedBy: .newlines)
            .flatMap(splitLongLine)
            .compactMap(cleanLine)
            .filter { filter?($0) ?? true }

        var seen: Set<String> = []
        let unique = lines.filter { line in
            let key = normalized(line)
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }

        return Array(unique.prefix(8))
    }

    private static func splitLongLine(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 90 else { return [trimmed] }

        let pieces = trimmed
            .replacingOccurrences(of: "；", with: "。")
            .components(separatedBy: CharacterSet(charactersIn: "。;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return pieces.isEmpty ? [trimmed] : pieces
    }

    private static func cleanLine(_ line: String) -> String? {
        let cleaned = reflowInlineText(line)
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\d+(\.\d+)*\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[（(]?\d+[）)]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[・\-●]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        guard cleaned.count > 1, !looksLikeHeading(cleaned) else { return nil }
        return cleaned
    }

    private static func looksLikeHeading(_ line: String) -> Bool {
        let normalizedLine = normalized(line)
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
        ].map(normalized)
        return headings.contains(normalizedLine)
    }

    private static func reflowText(_ text: String) -> String {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var merged: [String] = []
        for line in lines {
            if shouldStartNewLine(line, previous: merged.last) {
                merged.append(line)
            } else if let previous = merged.popLast() {
                merged.append(joinJapaneseText(previous, line))
            } else {
                merged.append(line)
            }
        }

        return merged.joined(separator: "\n")
    }

    private static func reflowInlineText(_ text: String) -> String {
        normalizeJapaneseSpacing(text
            .replacingOccurrences(of: #"\s*\n\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func shouldStartNewLine(_ line: String, previous: String?) -> Bool {
        guard let previous else { return true }
        if line.range(of: #"^\d+(\.\d+)*\s"#, options: .regularExpression) != nil { return true }
        if line.range(of: #"^[（(]?\d+[）)]"#, options: .regularExpression) != nil { return true }
        if line.range(of: #"^[・●■□※]"#, options: .regularExpression) != nil { return true }
        if previous.hasSuffix("。") || previous.hasSuffix("；") || previous.hasSuffix("：") || previous.hasSuffix(":") { return true }
        return false
    }

    private static func joinJapaneseText(_ lhs: String, _ rhs: String) -> String {
        if lhs.hasSuffix("-") {
            return normalizeJapaneseSpacing(String(lhs.dropLast()) + rhs)
        }
        if shouldJoinWithoutSpace(lhs, rhs) {
            return normalizeJapaneseSpacing(lhs + rhs)
        }
        return normalizeJapaneseSpacing(lhs + " " + rhs)
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

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
    }

    static func isMechanismLine(_ line: String) -> Bool {
        let normalizedLine = normalized(line)

        let excluded = [
            "副作用",
            "有害事象",
            "悪心",
            "傾眠",
            "投与群",
            "プラセボ",
            "信頼区間",
            "p値",
            "LSAS",
            "MADRS",
            "試験",
            "臨床成績",
            "比較",
            "スコア"
        ].map(normalized)

        if excluded.contains(where: { normalizedLine.contains($0) }) {
            return false
        }

        let included = [
            "作用",
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
        ].map(normalized)

        return included.contains(where: { normalizedLine.contains($0) })
    }
}

private struct DisplayAdverseEffect: Identifiable {
    let id = UUID()
    let name: String
    let frequency: String
    let detail: String?

    static func filtered(from effects: [Medicine.AdverseEffect]) -> [DisplayAdverseEffect] {
        var seen: Set<String> = []

        return effects.compactMap { effect in
            let name = cleaned(effect.name)
            let detail = cleaned(effect.detail)
            let key = normalized(name)
            guard !name.isEmpty, !seen.contains(key) else { return nil }
            seen.insert(key)

            let visibleDetail = shouldHideDetail(name: name, detail: detail) ? nil : detail
            return DisplayAdverseEffect(
                name: name,
                frequency: cleanedFrequency(effect.frequency),
                detail: visibleDetail?.isEmpty == true ? nil : visibleDetail
            )
        }
    }

    private static func shouldHideDetail(name: String, detail: String) -> Bool {
        let normalizedName = normalized(name)
        let normalizedDetail = normalized(detail)
        guard !normalizedName.isEmpty, !normalizedDetail.isEmpty else { return true }
        if normalizedName == normalizedDetail { return true }
        if normalizedDetail.hasPrefix(normalizedName), normalizedDetail.count <= normalizedName.count + 8 { return true }
        if normalizedDetail.contains(normalizedName), normalizedDetail.count <= normalizedName.count * 2 { return true }
        return false
    }

    private static func cleaned(_ text: String) -> String {
        normalizeJapaneseSpacing(text)
            .replacingOccurrences(of: #"\[[^\]]+参照\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\d+(\.\d+)*\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[（(]?\d+[）)]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func cleanedFrequency(_ text: String) -> String {
        let cleanedText = cleaned(text)
        return cleanedText.isEmpty ? "記載あり" : cleanedText
    }

    private static func normalized(_ text: String) -> String {
        cleaned(text)
            .folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
    }

    private static func normalizeJapaneseSpacing(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"(?<=[ぁ-んァ-ヶ一-龠])\s+(?=[ぁ-んァ-ヶ一-龠])"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?<=[ぁ-んァ-ヶ一-龠])\s+(?=[、。，．・）」』])"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+([、。，．・）」』])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct PriceRow: View {
    let name: String; let price: Double; let maker: String; let color: Color; let unit: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.caption).fontWeight(.semibold)
                Text(maker).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            if price > 0 {
                Text("¥\(String(format: "%.2f", price))/\(unit)")
                    .font(.subheadline).fontWeight(.bold).foregroundColor(color)
                    .fontDesign(.monospaced)
            } else {
                Text("未取得")
                    .font(.subheadline).fontWeight(.bold).foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct InteractionRow: View {
    let interaction: Medicine.Interaction
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(interaction.drug).font(.subheadline).fontWeight(.semibold)
                Spacer()
                SeverityBadge(severity: interaction.severity)
            }
            Text("機序: \(interaction.mechanism)")
                .font(.caption).foregroundColor(.secondary).lineSpacing(3)
            Text("対応: \(interaction.action)")
                .font(.caption).foregroundColor(.appBlue).lineSpacing(3)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - GeneralDetailView
struct GeneralDetailView: View {
    let medicine: Medicine
    var g: Medicine.GeneralInfo { medicine.general }

    var body: some View {
        VStack(spacing: 12) {
            SectionBox(title: "この薬はどんな薬？", accentColor: .appGreen) {
                ReadableTextBlock(text: g.whatIsIt, icon: "checkmark.circle.fill", color: .appGreen)
            }.padding(.horizontal)

            SectionBox(title: usageSectionTitle(for: medicine), accentColor: .appGreen) {
                ReadableTextBlock(text: g.howToTake, icon: usageSectionIcon(for: medicine), color: .appGreen)
            }.padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Label("飲み合わせで注意が必要な薬", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).fontWeight(.bold).foregroundColor(.appOrange)
                ReadableTextBlock(text: g.interactionWarning, icon: "exclamationmark.circle.fill", color: .appOrange)
            }
            .padding(14)
            .background(Color.appYellow.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appOrange.opacity(0.3), lineWidth: 1))
            .padding(.horizontal)

            SectionBox(title: "気をつけたい副作用", accentColor: .appOrange) {
                VStack(spacing: 0) {
                    ForEach(g.sideEffects) { se in
                        HStack(alignment: .top, spacing: 12) {
                            Text(se.icon).font(.title2)
                            VStack(alignment: .leading, spacing: 3) {
                            Text(se.name).font(.subheadline).fontWeight(.semibold)
                                Text(se.detail).font(.caption).foregroundColor(.appTextSecondary).lineSpacing(3)
                            }
                        }
                        .padding(.vertical, 10)
                        Divider()
                    }
                }
            }.padding(.horizontal)

            SectionBox(title: "日常生活での注意点", accentColor: .appBlue) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(g.dailyLife, id: \.self) { dl in
                        Label(dl, systemImage: "checkmark.square.fill")
                            .font(.subheadline)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appBlue, Color(.label))
                            .lineLimit(nil)
                    }
                }
            }.padding(.horizontal)

            SectionBox(title: "よくある質問", accentColor: .appPurple) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(g.qa) { qa in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Q. \(qa.q)").font(.subheadline).fontWeight(.bold).foregroundColor(.appPurple)
                            Text("A. \(qa.a)").font(.subheadline).lineSpacing(4).padding(.leading, 8)
                        }
                    }
                }
            }.padding(.horizontal)
        }
    }
}

private func usageSectionTitle(for medicine: Medicine) -> String {
    switch medicine.category {
    case "点眼薬", "外用薬", "吸入配合剤", "気管支拡張薬":
        return "使い方"
    case "輸液用電解質液":
        return "使用方法"
    default:
        if medicine.category.hasPrefix("注射用") || medicine.category == "麻酔・鎮静薬" || medicine.category == "救急循環作動薬" {
            return "使用方法"
        }
        return "飲み方"
    }
}

private func usageSectionIcon(for medicine: Medicine) -> String {
    switch medicine.category {
    case "点眼薬":
        return "eye.fill"
    case "外用薬":
        return "bandage.fill"
    case "吸入配合剤", "気管支拡張薬":
        return "wind"
    case "輸液用電解質液":
        return "cross.case.fill"
    default:
        if medicine.category.hasPrefix("注射用") || medicine.category == "麻酔・鎮静薬" || medicine.category == "救急循環作動薬" {
            return "cross.case.fill"
        }
        return "pills.fill"
    }
}

private func proAccentColor(for title: String) -> Color {
    let normalized = title.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
    if normalized.contains("禁忌") || normalized.contains("警告") || normalized.contains("相互作用") {
        return .appRed
    }
    if normalized.contains("副作用") || normalized.contains("有害事象") {
        return .appOrange
    }
    if normalized.contains("薬物動態") || normalized.contains("血中濃度") {
        return .appTeal
    }
    if normalized.contains("薬効薬理") || normalized.contains("作用機序") {
        return .appBlue
    }
    if normalized.contains("用法") || normalized.contains("用量") || normalized.contains("効能") || normalized.contains("効果") {
        return .appIndigo
    }
    if normalized.contains("背景を有する患者") || normalized.contains("妊婦") || normalized.contains("授乳") {
        return .appPurple
    }
    return .appIndigo
}

private func proIcon(for title: String) -> String {
    let normalized = title.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "ja_JP"))
    if normalized.contains("禁忌") || normalized.contains("警告") {
        return "exclamationmark.shield.fill"
    }
    if normalized.contains("相互作用") {
        return "exclamationmark.arrow.triangle.2.circlepath"
    }
    if normalized.contains("副作用") || normalized.contains("有害事象") {
        return "bandage.fill"
    }
    if normalized.contains("薬物動態") || normalized.contains("血中濃度") {
        return "waveform.path.ecg"
    }
    if normalized.contains("薬効薬理") || normalized.contains("作用機序") {
        return "cross.case.fill"
    }
    if normalized.contains("用法") || normalized.contains("用量") {
        return "pills.fill"
    }
    if normalized.contains("効能") || normalized.contains("効果") {
        return "staroflife.fill"
    }
    if normalized.contains("背景を有する患者") || normalized.contains("妊婦") || normalized.contains("授乳") {
        return "person.2.fill"
    }
    return "doc.text.fill"
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: rows.last.map { $0.maxY } ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        for row in rows {
            for item in row.items {
                item.view.place(at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + item.y),
                                proposal: ProposedViewSize(item.size))
            }
        }
    }

    private struct Row { var items: [(view: LayoutSubview, x: CGFloat, y: CGFloat, size: CGSize)] = []; var maxY: CGFloat = 0 }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = proposal.width ?? 300

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !currentRow.items.isEmpty {
                rows.append(currentRow)
                y += (currentRow.items.map { $0.size.height }.max() ?? 0) + spacing
                x = 0
                currentRow = Row()
            }
            currentRow.items.append((view: view, x: x, y: y, size: size))
            currentRow.maxY = y + size.height
            x += size.width + spacing
        }
        if !currentRow.items.isEmpty { rows.append(currentRow) }
        return rows
    }
}
