import SwiftUI

/// Interactive hardware signal-chain map for Drummer's Path stages,
/// paired with `DrummerModuleInspectorCard` for the right-hand inspector column.
@MainActor
struct DrummerPathMapView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let stages: [DrummerPathStageModel]
    @Binding var selectedStageIndex: Int
    @Binding var selectedNodeId: Int?
    let availableKeys: Int
    let onPlayLesson: (Lesson) -> Void
    let onUnlockKit: (DrumKitDescriptor) -> Void

    @State private var selectedPageByStage: [String: Int] = [:]

    private var language: AppLanguage { settings.languagePreference }

    private var currentStage: DrummerPathStageModel? {
        guard !stages.isEmpty else { return nil }
        let clamped = min(max(0, selectedStageIndex), stages.count - 1)
        return stages[clamped]
    }

    private var focusedNode: DrummerPathNode? {
        guard let stage = currentStage else { return nil }
        return Self.resolveFocusedNode(in: stage, selectedNodeId: selectedNodeId)
    }

    static func resolveFocusedNode(in stage: DrummerPathStageModel, selectedNodeId: Int?) -> DrummerPathNode? {
        if let selectedNodeId, let match = stage.nodes.first(where: { $0.id == selectedNodeId }) {
            return match
        }
        return stage.activeNode ?? stage.nodes.first(where: { $0.state != .locked }) ?? stage.nodes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            stageSwitcher

            if let stage = currentStage {
                signalMapChassis(stage: stage)
                    .frame(maxHeight: .infinity)

                techniquesStrip
            }
        }
    }

    // MARK: - Stage Switcher Cards

    private var stageSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stages) { stage in
                    let isSelected = stage.index == selectedStageIndex
                    let isDone = stage.completedCount == stage.totalCount && stage.totalCount > 0
                    Button {
                        if reduceMotion {
                            selectedStageIndex = stage.index
                            selectedNodeId = nil
                        } else {
                            withAnimation(.easeOut(duration: 0.16)) {
                                selectedStageIndex = stage.index
                                selectedNodeId = nil
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("STAGE \(stage.index + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? Theme.orange : Color.white.opacity(0.55))
                                Spacer(minLength: 4)
                                if isDone || stage.isExamCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.50))
                                }
                            }

                            Text(stage.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)

                            Text(stage.primaryKit.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(minWidth: 138, alignment: .leading)
                        .background(
                            isSelected ? Color(red: 0.11, green: 0.095, blue: 0.075) : Color(red: 0.078, green: 0.078, blue: 0.090),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(isSelected ? Theme.orange : Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: isSelected ? 1.5 : 1)
                        }
                        .shadow(color: isSelected ? Theme.orange.opacity(0.25) : .clear, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Locked Kit Banner

    private func lockedKitBanner(kit: DrumKitDescriptor) -> some View {
        let canUnlock = availableKeys >= kit.unlockCost
        let lockTitle = language == .czech
            ? "Vyžaduje sadu \(kit.name)"
            : "Requires \(kit.name) kit"
        let buttonTitle = language == .czech
            ? "Odemknout sadu \(kit.name) (1 klíč)"
            : "Unlock \(kit.name) kit (1 key)"

        return HStack(spacing: Theme.Space.controlGap) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(lockTitle)
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Color.white)
                Text(kit.studioTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.62))
            }

            Spacer(minLength: 8)

            Button {
                onUnlockKit(kit)
            } label: {
                Text(buttonTitle)
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(canUnlock ? Color.black : Color.white)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .background(
                        canUnlock ? Theme.orange : Color.white.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.button)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Theme.orange.opacity(0.55), lineWidth: 1)
        }
    }

    // MARK: - Signal Map Chassis

    private func signalMapChassis(stage: DrummerPathStageModel) -> some View {
        let pages = stagePages(for: stage)
        let activePageIdx = resolvedPageIndex(for: stage, pages: pages)
        let displayNodes = pages.indices.contains(activePageIdx) ? pages[activePageIdx].nodes : stage.nodes
        let bossPageIndex = pages.firstIndex(where: { $0.nodes.contains(where: \.isBoss) })
        let pageTopologies = DrummerStageTopology.topologiesForStage(
            stageId: stage.id,
            pageCount: pages.count,
            bossPageIndex: bossPageIndex,
            stageBaseTopology: stage.topology,
            nodeCounts: pages.map(\.nodes.count)
        )
        let activeTopology = pageTopologies.indices.contains(activePageIdx) ? pageTopologies[activePageIdx] : stage.topology
        let subtitle = language == .czech
            ? "\(activeTopology.title(language: language)) · Dokonči všech \(stage.totalCount) modulů pro zvládnutí etapy"
            : "\(activeTopology.title(language: language)) · Complete all \(stage.totalCount) hardware modules to master stage"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("STAGE \(stage.index + 1) · \(stage.title.uppercased())")
                        .font(Theme.boldDisplay(18))
                        .foregroundStyle(Color.white)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                Text("\(stage.completedCount) / \(stage.totalCount) \(language == .czech ? "HOTOVO" : "DONE")")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                    }
            }

            if pages.count > 1 {
                stagePageSwitcher(stage: stage, pages: pages, activeIndex: activePageIdx)
            }

            GeometryReader { geo in
                let requiredWidth = minimumCanvasWidth(for: displayNodes, topology: activeTopology)
                let canvasWidth = max(geo.size.width, requiredWidth)
                let canvasSize = CGSize(width: canvasWidth, height: geo.size.height)
                let points = nodeCoordinates(
                    nodes: displayNodes,
                    topology: activeTopology,
                    in: canvasSize
                )
                let labelWidths = computeLabelWidths(points: points, canvasWidth: canvasWidth)

                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        rackGridLines

                        patchCableLayer(
                            nodes: displayNodes,
                            points: points,
                            topology: activeTopology,
                            canvasSize: canvasSize
                        )

                        ForEach(Array(displayNodes.enumerated()), id: \.element.id) { idx, node in
                            if idx < points.count {
                                let maxLabelW = idx < labelWidths.count ? labelWidths[idx] : 105
                                moduleNode(node: node, stage: stage, labelWidth: maxLabelW)
                                    .position(points[idx])
                            }
                        }
                    }
                    .frame(width: canvasWidth, height: geo.size.height)
                }
            }
            .frame(minHeight: 300, maxHeight: .infinity)
        }
        .padding(16)
        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.25)
        }
    }

    private func stagePageSwitcher(
        stage: DrummerPathStageModel,
        pages: [(label: String, nodes: [DrummerPathNode])],
        activeIndex: Int
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                    let isSelected = idx == activeIndex
                    let completedInPage = page.nodes.filter { $0.state == .completed }.count
                    let allDone = completedInPage == page.nodes.count
                    Button {
                        selectedPageByStage[stage.id] = idx
                        if let firstPlayable = page.nodes.first(where: { $0.state == .active }) ?? page.nodes.first {
                            selectedNodeId = firstPlayable.id
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if allDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(isSelected ? Color.black : Color(red: 0.35, green: 0.85, blue: 0.50))
                            }
                            Text(page.label)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.75))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(
                            isSelected ? Theme.orange : Color(red: 0.078, green: 0.078, blue: 0.090),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(isSelected ? Theme.orange : Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var rackGridLines: some View {
        Canvas { context, size in
            let step: CGFloat = 32
            var path = Path()
            for x in stride(from: step, to: size.width, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: step, to: size.height, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(Color.white.opacity(0.035)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    private func patchCableLayer(
        nodes: [DrummerPathNode],
        points: [CGPoint],
        topology: DrummerStageTopology,
        canvasSize: CGSize
    ) -> some View {
        Canvas { context, _ in
            let edges = buildEdges(nodes: nodes, topology: topology)
            for (edgeIdx, (fromIdx, toIdx)) in edges.enumerated() where fromIdx < points.count && toIdx < points.count {
                let start = points[fromIdx]
                let end = points[toIdx]
                let isLit = nodes[fromIdx].state == .completed && nodes[toIdx].state != .locked
                let isActiveLink = nodes[fromIdx].state == .completed && nodes[toIdx].state == .active

                let path = curvedCablePath(
                    from: start,
                    to: end,
                    topology: topology,
                    edgeIndex: edgeIdx,
                    canvasWidth: canvasSize.width
                )

                context.stroke(
                    path,
                    with: .color(Color.black.opacity(0.85)),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )

                let strokeColor: Color = (isLit || isActiveLink)
                    ? Theme.orange
                    : Color(red: 0.22, green: 0.22, blue: 0.26)

                if isLit || isActiveLink {
                    var glow = context
                    glow.addFilter(.shadow(color: Theme.orange.opacity(0.75), radius: 6, x: 0, y: 0))
                    glow.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 5])
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Builds a smooth cubic Bézier cable path with 8pt rounded entry/exit clearance so cables never cross node labels.
    private func curvedCablePath(
        from start: CGPoint,
        to end: CGPoint,
        topology: DrummerStageTopology,
        edgeIndex: Int,
        canvasWidth: CGFloat
    ) -> Path {
        var path = Path()
        path.move(to: start)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let cornerRadius: CGFloat = 8

        if abs(dy) > 8 {
            // Smooth S-curve exiting/entering along node centers cleanly above labels.
            let midX = (start.x + end.x) * 0.5
            let pull = max(cornerRadius, abs(dx) * 0.45)
            let c1x = dx >= 0 ? min(midX, start.x + pull) : max(midX, start.x - pull)
            let c2x = dx >= 0 ? max(midX, end.x - pull) : min(midX, end.x + pull)
            path.addCurve(
                to: end,
                control1: CGPoint(x: c1x, y: start.y),
                control2: CGPoint(x: c2x, y: end.y)
            )
            return path
        }

        // Horizontal peers: gentle arched Bézier cable (4–6 pt arc) instead of a stark flat line.
        let arcOffset: CGFloat = (edgeIndex % 2 == 0) ? -5 : 5
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x + dx * 0.32, y: start.y + arcOffset),
            control2: CGPoint(x: start.x + dx * 0.68, y: end.y + arcOffset)
        )
        return path
    }

    private func moduleNode(node: DrummerPathNode, stage: DrummerPathStageModel, labelWidth: CGFloat) -> some View {
        let isFocused = focusedNode?.id == node.id
        let isCompleted = node.state == .completed
        let isActive = node.state == .active
        let isLocked = node.state == .locked
        let lit = isCompleted || isActive || isFocused

        let borderColor: Color = lit ? Theme.orange : Color(red: 0.204, green: 0.204, blue: 0.239)
        let fillColor: Color = if node.isBoss {
            lit ? Color(red: 0.16, green: 0.12, blue: 0.06) : Color(red: 0.09, green: 0.08, blue: 0.07)
        } else if isActive || isFocused {
            Color(red: 0.13, green: 0.10, blue: 0.06)
        } else {
            Color(red: 0.078, green: 0.078, blue: 0.090)
        }

        let boxWidth: CGFloat = node.isBoss ? 114 : (node.isSideQuest ? 70 : 64)
        let boxHeight: CGFloat = 62
        let titleText = node.isBoss
            ? (language == .czech ? "Zkouška etapy · \(stage.title)" : "\(stage.title) Stage Exam")
            : "\(node.orderIndex + 1). \(settings.localized(node.lesson.title))"

        return Button {
            selectedNodeId = node.id
        } label: {
            ZStack {
                Group {
                    if node.isSideQuest {
                        HexagonShape()
                            .fill(fillColor)
                            .overlay {
                                HexagonShape()
                                    .stroke(borderColor, lineWidth: isFocused ? 2.2 : 1.5)
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(fillColor)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(borderColor, lineWidth: isFocused ? 2.2 : 1.5)
                            }
                    }
                }
                .frame(width: boxWidth, height: boxHeight)
                .shadow(color: lit ? Theme.orange.opacity(isFocused ? 0.55 : 0.35) : Color.black.opacity(0.5),
                        radius: lit ? (isFocused ? 12 : 8) : 4)

                VStack(spacing: 4) {
                    if node.isBoss {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(lit ? Theme.orange : Color.white.opacity(0.55))
                            Text("BOSS EXAM")
                                .font(.system(size: 10.5, weight: .black, design: .monospaced))
                                .foregroundStyle(lit ? Theme.orange : Color.white.opacity(0.55))
                        }
                    } else {
                        Text("\(node.orderIndex + 1)")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(isLocked ? Color.white.opacity(0.45) : Color.white)
                    }

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    } else {
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { starIdx in
                                Image(systemName: starIdx < node.stars ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundStyle(starIdx < node.stars ? Theme.orange : Color.white.opacity(0.24))
                            }
                        }
                    }
                }

                // Perched badge on top edge for Boss or Technique/Side Quest
                if node.isBoss {
                    Text(language == .czech ? "STAGE BOSS · +1 KEY" : "STAGE BOSS · +1 KEY")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: Capsule())
                        .overlay { Capsule().strokeBorder(Theme.orange.opacity(0.8), lineWidth: 1) }
                        .offset(y: -boxHeight / 2)
                } else if node.isSideQuest {
                    Text(language == .czech ? "TECHNIQUE" : "TECHNIQUE")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: Capsule())
                        .overlay { Capsule().strokeBorder(Theme.orange.opacity(0.8), lineWidth: 1) }
                        .offset(y: -boxHeight / 2)
                }
            }
            .overlay(alignment: .bottom) {
                Text(titleText)
                    .font(.system(size: 11, weight: isFocused ? .bold : .medium))
                    .foregroundStyle(isLocked ? Color.white.opacity(0.48) : Color.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(width: labelWidth, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
                    .alignmentGuide(.bottom) { d in d[.top] }
                    .offset(y: 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nodeAccessibilityLabel(node))
    }

    // MARK: - Techniques Strip

    private var techniquesStrip: some View {
        HStack(spacing: 10) {
            Text(language == .czech ? "TECHNIKY" : "TECHNIQUES")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.55))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stages.prefix(6)) { stage in
                        let pct = stage.totalCount > 0
                            ? Int((Double(stage.completedCount) / Double(stage.totalCount) * 100).rounded())
                            : 0
                        let complete = stage.totalCount > 0 && stage.completedCount == stage.totalCount
                        HStack(spacing: 5) {
                            Image(systemName: complete ? "checkmark" : "circle.fill")
                                .font(.system(size: complete ? 9 : 6, weight: .bold))
                                .foregroundStyle(complete ? Color(red: 0.35, green: 0.85, blue: 0.50) : Theme.orange)
                            Text(complete ? stage.title : "\(stage.title) \(pct)%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(complete ? 0.92 : 0.72))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(complete ? Color(red: 0.35, green: 0.85, blue: 0.50).opacity(0.45) : Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
        }
    }

    // MARK: - Stage Pagination & Geometry

    private func stagePages(for stage: DrummerPathStageModel) -> [(label: String, nodes: [DrummerPathNode])] {
        let all = stage.nodes
        guard all.count > 6 else {
            return [("", all)]
        }

        let pageSize = 6
        var ranges: [Range<Int>] = []
        var start = 0
        while start < all.count {
            let remaining = all.count - start
            // Fold a lone trailing Boss node into the previous page so no page holds only 1 node.
            if remaining == pageSize + 1 {
                ranges.append(start..<all.count)
                break
            }
            let end = min(all.count, start + pageSize)
            ranges.append(start..<end)
            start = end
        }

        return ranges.map { range in
            let slice = Array(all[range])
            let hasBoss = slice.contains(where: \.isBoss)
            let lessonSlice = hasBoss ? Array(slice.dropLast()) : slice
            let firstNum = lessonSlice.first.map { $0.orderIndex + 1 } ?? (range.lowerBound + 1)
            let lastNum = lessonSlice.last.map { $0.orderIndex + 1 } ?? firstNum
            let numberPart = firstNum == lastNum ? "\(firstNum)" : "\(firstNum)–\(lastNum)"
            let label = hasBoss ? "\(numberPart) + BOSS" : numberPart
            return (label: label, nodes: slice)
        }
    }

    private func resolvedPageIndex(
        for stage: DrummerPathStageModel,
        pages: [(label: String, nodes: [DrummerPathNode])]
    ) -> Int {
        if let saved = selectedPageByStage[stage.id], pages.indices.contains(saved) {
            // If user clicked a node programmatically or focused node is on another page, keep saved unless focusedNode changed
            if let focusedId = selectedNodeId,
               let matchingPage = pages.firstIndex(where: { $0.nodes.contains(where: { $0.id == focusedId }) }) {
                return matchingPage
            }
            return saved
        }
        if let activeId = stage.activeNode?.id,
           let activePage = pages.firstIndex(where: { $0.nodes.contains(where: { $0.id == activeId }) }) {
            return activePage
        }
        return 0
    }

    private func minimumCanvasWidth(for nodes: [DrummerPathNode], topology: DrummerStageTopology) -> CGFloat {
        let count = nodes.count
        guard count > 1 else { return 240 }
        let padLeading: CGFloat = 72
        let padTrailing: CGFloat = 86
        let minCenterStep: CGFloat = 118

        switch topology {
        case .splitFork where count >= 4:
            let columns: Int = switch count {
            case 4: 3
            case 5: 4
            default: 5
            }
            return padLeading + padTrailing + CGFloat(columns - 1) * minCenterStep
        default:
            return padLeading + padTrailing + CGFloat(count - 1) * minCenterStep
        }
    }

    private func computeLabelWidths(points: [CGPoint], canvasWidth: CGFloat) -> [CGFloat] {
        guard !points.isEmpty else { return [] }
        return points.indices.map { i in
            let p = points[i]
            var minSameRowGap: CGFloat = canvasWidth
            for j in points.indices where i != j {
                let q = points[j]
                if abs(p.y - q.y) < 58 {
                    minSameRowGap = min(minSameRowGap, abs(p.x - q.x))
                }
            }
            let edgeAllowance = min(p.x, max(40, canvasWidth - p.x)) * 1.85
            let maxPossible = min(minSameRowGap - 14, edgeAllowance)
            return min(105, max(72, maxPossible))
        }
    }

    private func nodeCoordinates(
        nodes: [DrummerPathNode],
        topology: DrummerStageTopology,
        in size: CGSize
    ) -> [CGPoint] {
        let count = nodes.count
        guard count > 0 else { return [] }
        let padLeading: CGFloat = 72
        let padTrailing: CGFloat = 86
        let usableW = max(160, size.width - padLeading - padTrailing)
        let topY = max(54, size.height * 0.22)
        let midY = size.height * 0.45
        let botY = min(size.height - 68, size.height * 0.68)

        switch topology {
        case .signalLine:
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let gentleArc = count <= 2 ? 0 : sin(t * .pi) * -16
                return CGPoint(x: padLeading + t * usableW, y: midY + gentleArc)
            }

        case .serpentine:
            // Strictly left-to-right 2-level S-wave: entry top-left, exit top-right.
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let x = padLeading + t * usableW
                let y: CGFloat
                if count <= 3 {
                    y = (i % 2 == 0) ? topY : botY
                } else {
                    let wave = sin(t * .pi * 2.0 + .pi * 0.5)
                    y = midY - wave * ((botY - topY) * 0.48)
                }
                return CGPoint(x: x, y: y)
            }

        case .diagonalClimb:
            // Rising staircase / diagonal wave from bottom-left up to top-right Boss.
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let x = padLeading + t * usableW
                let climb = botY + (topY - botY) * t
                return CGPoint(x: x, y: climb)
            }

        case .chevronWave:
            // Bold alternating high/low V/W wave ending high on the last/Boss node.
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let distFromEnd = (count - 1) - i
                let isTop = (distFromEnd % 2 == 0)
                return CGPoint(x: padLeading + t * usableW, y: isTop ? topY : botY)
            }

        case .splitFork:
            guard count >= 4 else {
                return nodeCoordinates(nodes: nodes, topology: .signalLine, in: size)
            }
            if count == 4 {
                return [
                    CGPoint(x: padLeading, y: midY),
                    CGPoint(x: padLeading + usableW * 0.50, y: topY),
                    CGPoint(x: padLeading + usableW * 0.50, y: botY),
                    CGPoint(x: padLeading + usableW, y: midY)
                ]
            }
            if count == 5 {
                return [
                    CGPoint(x: padLeading, y: midY),
                    CGPoint(x: padLeading + usableW * 0.28, y: midY),
                    CGPoint(x: padLeading + usableW * 0.64, y: topY),
                    CGPoint(x: padLeading + usableW * 0.64, y: botY),
                    CGPoint(x: padLeading + usableW, y: midY)
                ]
            }
            if count == 6 {
                return [
                    CGPoint(x: padLeading, y: midY),
                    CGPoint(x: padLeading + usableW * 0.24, y: midY),
                    CGPoint(x: padLeading + usableW * 0.50, y: topY),
                    CGPoint(x: padLeading + usableW * 0.50, y: botY),
                    CGPoint(x: padLeading + usableW * 0.76, y: midY),
                    CGPoint(x: padLeading + usableW, y: midY)
                ]
            }
            // 7 nodes: 0 -> 1 -> (2,3) -> (4,5) -> 6 (strictly ascending columns, >= 118 pt apart).
            return [
                CGPoint(x: padLeading, y: midY),
                CGPoint(x: padLeading + usableW * 0.22, y: midY),
                CGPoint(x: padLeading + usableW * 0.46, y: topY),
                CGPoint(x: padLeading + usableW * 0.46, y: botY),
                CGPoint(x: padLeading + usableW * 0.72, y: topY),
                CGPoint(x: padLeading + usableW * 0.72, y: botY),
                CGPoint(x: padLeading + usableW, y: midY)
            ]

        case .steppedArc:
            // Bridge arch rising from lower-left entry over top center to right exit.
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let x = padLeading + t * usableW
                let arch = sin(t * .pi)
                let y = botY - arch * (botY - topY)
                return CGPoint(x: x, y: y)
            }
        }
    }

    private func buildEdges(nodes: [DrummerPathNode], topology: DrummerStageTopology) -> [(Int, Int)] {
        let count = nodes.count
        guard count > 1 else { return [] }

        switch topology {
        case .signalLine, .serpentine, .diagonalClimb, .chevronWave, .steppedArc:
            return (0..<(count - 1)).map { ($0, $0 + 1) }

        case .splitFork:
            guard count >= 4 else { return (0..<(count - 1)).map { ($0, $0 + 1) } }
            switch count {
            case 4:
                return [(0, 1), (0, 2), (1, 3), (2, 3)]
            case 5:
                return [(0, 1), (1, 2), (1, 3), (2, 4), (3, 4)]
            case 6:
                return [(0, 1), (1, 2), (1, 3), (2, 4), (3, 4), (4, 5)]
            default:
                // 7 nodes: 0 -> 1 -> (2, 3) -> (4, 5) -> 6
                return [(0, 1), (1, 2), (1, 3), (2, 4), (3, 5), (4, 6), (5, 6)]
            }
        }
    }

    private func nodeAccessibilityLabel(_ node: DrummerPathNode) -> String {
        let title = settings.localized(node.lesson.title)
        let role = node.isBoss ? (language == .czech ? "Zkouška etapy" : "Stage exam") : ""
        let stateText: String = switch node.state {
        case .completed: "\(node.stars) / 3 ★"
        case .active: language == .czech ? "Aktivní" : "Active"
        case .locked: language == .czech ? "Zamčeno" : "Locked"
        }
        return [role, title, stateText].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2
        let points: [CGPoint] = [
            CGPoint(x: cx, y: cy - ry),
            CGPoint(x: cx + rx, y: cy - ry * 0.45),
            CGPoint(x: cx + rx, y: cy + ry * 0.45),
            CGPoint(x: cx, y: cy + ry),
            CGPoint(x: cx - rx, y: cy + ry * 0.45),
            CGPoint(x: cx - rx, y: cy - ry * 0.45)
        ]
        path.move(to: points[0])
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }
}

/// Top-right Module Inspector card displaying full specs, rewards, and launch action for the selected node.
@MainActor
struct DrummerModuleInspectorCard: View {
    @Environment(SettingsManager.self) private var settings

    let stage: DrummerPathStageModel?
    let node: DrummerPathNode?
    let availableKeys: Int
    let onPlayLesson: (Lesson) -> Void
    let onUnlockKit: (DrumKitDescriptor) -> Void

    private var language: AppLanguage { settings.languagePreference }

    var body: some View {
        if let stage, let node {
            let canPlay = node.state != .locked
            let ctaTitle: String = if node.state == .completed {
                language == .czech ? "Znovu zahrát lekci" : "Replay Lesson"
            } else {
                language == .czech ? "Hrát lekci" : "Play Lesson"
            }

            let headerTag: String = if node.isBoss {
                language == .czech ? "ZKOUŠKA ETAPY\nBOSS MODUL" : "STAGE BOSS\nEXAMINATION"
            } else if node.isSideQuest {
                language == .czech ? "TECHNICKÁ\nVÝZVA" : "TECHNIQUE\nSIDE QUEST"
            } else {
                language == .czech ? "HARDWAROVÝ\nMODUL \(node.orderIndex + 1)" : "HARDWARE\nMODULE \(node.orderIndex + 1)"
            }

            let levelBonus = max(0, node.lesson.level - 1)
            let rewardXP = (node.isBoss ? 150 : 0) + 90 + levelBonus * 25
            let rewardDetail = node.isBoss
                ? "+\(rewardXP) XP · +3 TIMING · +3 MEMORY · +1 KIT KEY"
                : "+\(rewardXP) XP · +2 TIMING · +1 TECHNIQUE"

            let descriptionText: String = {
                let raw = settings.localized(node.lesson.text).trimmingCharacters(in: .whitespacesAndNewlines)
                if !raw.isEmpty { return raw }
                return language == .czech
                    ? "\(node.lesson.bars)takty · \(node.lesson.genre)"
                    : "\(node.lesson.bars)-bar \(node.lesson.genre.lowercased()) pattern."
            }()

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Text(headerTag)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.orange)

                    Spacer(minLength: 8)

                    Text(language == .czech ? "Sada: \(node.requiredKit.name)" : "Kit: \(node.requiredKit.name)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        node.isBoss
                            ? (language == .czech ? "Zkouška etapy · \(stage.title)" : "\(stage.title) Stage Exam")
                            : "\(node.orderIndex + 1). \(settings.localized(node.lesson.title))"
                    )
                        .font(Theme.boldDisplay(21))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)

                    Text(descriptionText)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    metricBox(label: "TEMPO", value: "\(node.lesson.targetBpm) BPM")
                    metricBox(label: language == .czech ? "DÉLKA" : "LENGTH",
                              value: language == .czech ? "\(node.lesson.bars) takty" : "\(node.lesson.bars) Bars")
                    masteryBox(stars: node.stars)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(language == .czech ? "ODMĚNA MODULU" : "MODULE REWARD")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(rewardDetail)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.orange)
                        .lineLimit(2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                }

                Button {
                    onPlayLesson(node.lesson)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(ctaTitle)
                            .font(Theme.strong(15))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .shadow(color: Theme.orange.opacity(canPlay ? 0.45 : 0), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(!canPlay)
                .opacity(canPlay ? 1 : 0.45)
            }
            .padding(14)
            .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.25)
            }
        }
    }

    private func metricBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
        }
    }

    private func masteryBox(stars: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MASTERY")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { idx in
                    Image(systemName: idx < stars ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(idx < stars ? Theme.orange : Color.white.opacity(0.25))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
        }
    }
}
