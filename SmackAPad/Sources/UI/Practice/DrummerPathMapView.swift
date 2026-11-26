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
                if let lockedKit = stage.lockedKit {
                    lockedKitBanner(kit: lockedKit)
                }

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
                                if stage.lockedKit != nil {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                } else if isDone || stage.isExamCompleted {
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
        let subtitle = language == .czech
            ? "\(stage.topology.title(language: language)) · Dokonči všech \(stage.totalCount) modulů pro zvládnutí etapy"
            : "\(stage.topology.title(language: language)) · Complete all \(stage.totalCount) hardware modules to master stage"

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

            GeometryReader { geo in
                let displayNodes = windowedNodes(for: stage)
                let points = nodeCoordinates(
                    nodes: displayNodes,
                    topology: stage.topology,
                    in: geo.size
                )

                ZStack {
                    rackGridLines

                    patchCableLayer(nodes: displayNodes, points: points, topology: stage.topology)

                    ForEach(Array(displayNodes.enumerated()), id: \.element.id) { idx, node in
                        if idx < points.count {
                            moduleNode(node: node, stage: stage)
                                .position(points[idx])
                        }
                    }
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
        topology: DrummerStageTopology
    ) -> some View {
        Canvas { context, _ in
            let edges = buildEdges(nodes: nodes, topology: topology)
            for (fromIdx, toIdx) in edges where fromIdx < points.count && toIdx < points.count {
                let start = points[fromIdx]
                let end = points[toIdx]
                let isLit = nodes[fromIdx].state == .completed && nodes[toIdx].state != .locked
                let isActiveLink = nodes[fromIdx].state == .completed && nodes[toIdx].state == .active

                var path = Path()
                path.move(to: start)
                if topology == .stepSequencer && abs(start.y - end.y) > 20 {
                    // Sweeping curved turnaround from top row down to second row
                    let sweepX = max(start.x, end.x) + 76
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: sweepX, y: start.y),
                        control2: CGPoint(x: sweepX, y: end.y)
                    )
                } else if abs(start.y - end.y) > 8 && abs(start.x - end.x) > 8 {
                    let midX = (start.x + end.x) * 0.5
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: midX, y: start.y),
                        control2: CGPoint(x: midX, y: end.y)
                    )
                } else {
                    path.addLine(to: end)
                }

                context.stroke(
                    path,
                    with: .color(Color.black.opacity(0.85)),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
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
                        style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 5])
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func moduleNode(node: DrummerPathNode, stage: DrummerPathStageModel) -> some View {
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
        let titleText = "\(node.orderIndex + 1). \(settings.localized(node.lesson.title))"

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
                        Text("BOSS EXAM")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(lit ? Theme.orange : Color.white.opacity(0.55))
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
                    .frame(width: 118)
                    .offset(y: 34)
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

    // MARK: - Topology Windowing & Geometry

    private func windowedNodes(for stage: DrummerPathStageModel) -> [DrummerPathNode] {
        let all = stage.nodes
        let maxNodes = 6
        guard all.count > maxNodes else { return all }

        let activeIdx = all.firstIndex(where: { $0.state == .active }) ?? 0
        let start = max(0, min(activeIdx - 2, all.count - maxNodes))
        var slice = Array(all[start..<min(start + maxNodes - 1, all.count - 1)])
        if let boss = all.last {
            slice.append(boss)
        }
        return slice
    }

    private func nodeCoordinates(
        nodes: [DrummerPathNode],
        topology: DrummerStageTopology,
        in size: CGSize
    ) -> [CGPoint] {
        let count = nodes.count
        guard count > 0 else { return [] }
        let padLeading: CGFloat = 68
        let padTrailing: CGFloat = 86
        let usableW = max(140, size.width - padLeading - padTrailing)
        let midY = size.height * 0.44

        switch topology {
        case .straightLine:
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                return CGPoint(x: padLeading + t * usableW, y: midY)
            }

        case .splitFork:
            guard count >= 5 else {
                return nodeCoordinates(nodes: nodes, topology: .straightLine, in: size)
            }
            let topY = size.height * 0.24
            let botY = size.height * 0.68
            return (0..<count).map { i in
                if i == 0 {
                    return CGPoint(x: padLeading, y: midY)
                } else if i == 1 {
                    return CGPoint(x: padLeading + usableW * 0.23, y: midY)
                } else if i == count - 1 {
                    return CGPoint(x: padLeading + usableW, y: midY)
                } else {
                    let branch = nodes[i].branchTrack ?? 0
                    let middleTotal = max(1, (count - 3 + 1) / 2)
                    let col = (i - 2) / 2
                    let step = usableW * 0.44 / CGFloat(max(1, middleTotal))
                    let x = padLeading + usableW * 0.46 + CGFloat(col) * step
                    return CGPoint(x: x, y: branch == 0 ? topY : botY)
                }
            }

        case .stepSequencer:
            let topCols = max(1, min(4, (count + 1) / 2 + (count >= 5 ? 1 : 0)))
            let row0Y = size.height * 0.24
            let row1Y = size.height * 0.68
            return (0..<count).map { i in
                if i < topCols {
                    let t = topCols == 1 ? 0.5 : CGFloat(i) / CGFloat(topCols - 1)
                    return CGPoint(x: padLeading + t * usableW, y: row0Y)
                } else {
                    let bottomIndex = i - topCols
                    let bottomCount = max(1, count - topCols)
                    // Right-to-left snake under columns (topCols - 2) ... 0
                    let colIndex = max(0, (topCols - 1) - 1 - bottomIndex)
                    let t = topCols <= 1 ? 0.5 : CGFloat(min(topCols - 1, colIndex + (bottomCount == 1 ? 1 : 0))) / CGFloat(max(1, topCols - 1))
                    return CGPoint(x: padLeading + t * usableW, y: row1Y)
                }
            }

        case .loopWithSideQuest:
            let mainNodes = nodes.filter { !$0.isSideQuest }
            let mainCount = mainNodes.count
            var mainIndexById: [Int: Int] = [:]
            for (mIdx, node) in mainNodes.enumerated() {
                mainIndexById[node.id] = mIdx
            }
            let mainY = size.height * 0.26
            let sideY = size.height * 0.70
            return nodes.map { node in
                if node.isSideQuest {
                    return CGPoint(x: padLeading + usableW * 0.60, y: sideY)
                }
                let mIdx = mainIndexById[node.id] ?? 0
                let t = mainCount <= 1 ? 0.5 : CGFloat(mIdx) / CGFloat(mainCount - 1)
                return CGPoint(x: padLeading + t * usableW, y: mainY)
            }
        }
    }

    private func buildEdges(nodes: [DrummerPathNode], topology: DrummerStageTopology) -> [(Int, Int)] {
        let count = nodes.count
        guard count > 1 else { return [] }

        switch topology {
        case .straightLine, .stepSequencer:
            return (0..<(count - 1)).map { ($0, $0 + 1) }

        case .splitFork:
            guard count >= 5 else { return (0..<(count - 1)).map { ($0, $0 + 1) } }
            var edges: [(Int, Int)] = [(0, 1)]
            let branch0 = (0..<count).filter { nodes[$0].branchTrack == 0 }
            let branch1 = (0..<count).filter { nodes[$0].branchTrack == 1 }
            let bossIdx = count - 1
            if let first0 = branch0.first { edges.append((1, first0)) }
            if let first1 = branch1.first { edges.append((1, first1)) }
            for i in 0..<max(0, branch0.count - 1) { edges.append((branch0[i], branch0[i + 1])) }
            for i in 0..<max(0, branch1.count - 1) { edges.append((branch1[i], branch1[i + 1])) }
            if let last0 = branch0.last { edges.append((last0, bossIdx)) }
            if let last1 = branch1.last { edges.append((last1, bossIdx)) }
            return edges

        case .loopWithSideQuest:
            let mainIndices = (0..<count).filter { !nodes[$0].isSideQuest }
            var edges: [(Int, Int)] = []
            for i in 0..<max(0, mainIndices.count - 1) {
                edges.append((mainIndices[i], mainIndices[i + 1]))
            }
            if let sideIdx = (0..<count).first(where: { nodes[$0].isSideQuest }) {
                let anchor = mainIndices.first ?? 0
                let rejoin = mainIndices.last ?? (count - 1)
                edges.append((anchor, sideIdx))
                edges.append((sideIdx, rejoin))
            }
            return edges
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
            let isKitLocked = stage.lockedKit != nil
            let ctaTitle: String = if let lockedKit = stage.lockedKit {
                language == .czech ? "Odemknout \(lockedKit.name) (1 klíč)" : "Unlock \(lockedKit.name) (1 key)"
            } else if node.state == .completed {
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

                    Text(language == .czech ? "Vyžaduje: \(node.requiredKit.name)" : "Requires: \(node.requiredKit.name) Kit")
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
                    Text("\(node.orderIndex + 1). \(settings.localized(node.lesson.title))")
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
                    if let lockedKit = stage.lockedKit {
                        onUnlockKit(lockedKit)
                    } else {
                        onPlayLesson(node.lesson)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isKitLocked ? "key.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(ctaTitle)
                            .font(Theme.strong(15))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .shadow(color: Theme.orange.opacity(canPlay || isKitLocked ? 0.45 : 0), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(!isKitLocked && !canPlay)
                .opacity((isKitLocked || canPlay) ? 1 : 0.45)
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
