import SwiftUI

/// Interactive hardware signal-patch map for Drummer's Path stages.
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
        if let selectedNodeId, let match = stage.nodes.first(where: { $0.id == selectedNodeId }) {
            return match
        }
        return stage.activeNode ?? stage.nodes.first(where: { $0.state != .locked }) ?? stage.nodes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            stageSwitcher

            if let stage = currentStage {
                if let lockedKit = stage.lockedKit {
                    lockedKitBanner(kit: lockedKit)
                }

                signalMapChassis(stage: stage)

                selectedNodeFooter(stage: stage)
            }
        }
        .padding(Theme.Space.regular)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    // MARK: - Stage Switcher

    private var stageSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.small) {
                ForEach(stages) { stage in
                    let isSelected = stage.index == selectedStageIndex
                    let accent = kitAccentColor(for: stage.primaryKit.kitId)
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
                        HStack(spacing: 6) {
                            Image(systemName: stage.lockedKit != nil ? "lock.fill" : stage.topology.systemImage)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isSelected ? Theme.black : (stage.isExamCompleted ? Theme.orange : accent))

                            Text(stage.index == 0 ? stage.title : "L\(stage.level) · \(stage.title)")
                                .font(Theme.caption.weight(isSelected ? .semibold : .medium))
                                .lineLimit(1)

                            Text("\(stage.completedCount)/\(stage.totalCount)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .opacity(0.72)
                        }
                        .foregroundStyle(isSelected ? Theme.black : Theme.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(
                            isSelected ? accent : Theme.background,
                            in: RoundedRectangle(cornerRadius: Theme.Radius.button)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                .strokeBorder(isSelected ? accent : Theme.hairline, lineWidth: 1)
                        }
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
                    .foregroundStyle(Theme.white)
                Text(kit.studioTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.white.opacity(0.62))
            }

            Spacer(minLength: 8)

            Button {
                onUnlockKit(kit)
            } label: {
                Text(buttonTitle)
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(canUnlock ? Theme.black : Theme.white)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .background(
                        canUnlock ? Theme.orange : Theme.white.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.button)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Theme.orange.opacity(0.45), lineWidth: 1)
        }
    }

    // MARK: - Signal Map Chassis

    private func signalMapChassis(stage: DrummerPathStageModel) -> some View {
        let accent = kitAccentColor(for: stage.primaryKit.kitId)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                Text(stage.topology.title(language: language).uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.white.opacity(0.68))

                Text("·")
                    .foregroundStyle(Theme.white.opacity(0.35))

                Text(stage.primaryKit.name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(accent)

                Spacer()

                Text(stage.isExamCompleted
                     ? (language == .czech ? "Zkouška splněna" : "Exam passed")
                     : (language == .czech ? "Zkouška etapy = +1 klíč" : "Stage exam = +1 key"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(stage.isExamCompleted ? Theme.orange : Theme.white.opacity(0.55))
            }

            GeometryReader { geo in
                let displayNodes = windowedNodes(for: stage)
                let points = nodeCoordinates(
                    nodes: displayNodes,
                    topology: stage.topology,
                    in: geo.size
                )

                ZStack {
                    patchCableLayer(nodes: displayNodes, points: points, topology: stage.topology, accent: accent)

                    ForEach(Array(displayNodes.enumerated()), id: \.element.id) { idx, node in
                        if idx < points.count {
                            nodeButton(node: node, accent: accent)
                                .position(points[idx])
                        }
                    }
                }
            }
            .frame(height: 224)
        }
        .padding(Theme.Space.controlGap)
        .background(Color(red: 21/255, green: 20/255, blue: 18/255), in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func patchCableLayer(
        nodes: [DrummerPathNode],
        points: [CGPoint],
        topology: DrummerStageTopology,
        accent: Color
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
                let midX = (start.x + end.x) * 0.5
                if abs(start.y - end.y) > 8 && abs(start.x - end.x) > 8 {
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: midX, y: start.y),
                        control2: CGPoint(x: midX, y: end.y)
                    )
                } else {
                    path.addLine(to: end)
                }

                let strokeColor: Color = if isActiveLink {
                    Theme.orange
                } else if isLit {
                    accent.opacity(0.85)
                } else {
                    Theme.white.opacity(0.16)
                }

                context.stroke(
                    path,
                    with: .color(strokeColor),
                    style: StrokeStyle(lineWidth: isLit ? 2.5 : 1.5, lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func nodeButton(node: DrummerPathNode, accent: Color) -> some View {
        let isFocused = focusedNode?.id == node.id
        let isCompleted = node.state == .completed
        let isActive = node.state == .active
        let isLocked = node.state == .locked

        let borderColor: Color = if isFocused || isActive {
            Theme.orange
        } else if isCompleted {
            accent.opacity(0.85)
        } else {
            Theme.white.opacity(0.18)
        }

        let fillColor: Color = if isActive {
            Theme.orange.opacity(0.18)
        } else if isCompleted {
            Color(red: 34/255, green: 32/255, blue: 28/255)
        } else {
            Color(red: 26/255, green: 25/255, blue: 22/255)
        }

        return Button {
            selectedNodeId = node.id
        } label: {
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    if node.isBoss {
                        Image(systemName: "key.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isCompleted || isActive ? Theme.orange : Theme.white.opacity(0.45))
                    } else if node.isSideQuest {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                    }

                    Text(node.isBoss ? "BOSS" : (node.isSideQuest ? "SIDE" : "\(node.orderIndex + 1)"))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(isLocked ? Theme.white.opacity(0.42) : Theme.white)
                }

                if isCompleted {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { starIdx in
                            Image(systemName: starIdx < node.stars ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(starIdx < node.stars ? Theme.orange : Theme.white.opacity(0.25))
                        }
                    }
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.white.opacity(0.35))
                } else {
                    Circle()
                        .fill(Theme.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: node.isBoss ? 68 : 58, height: 48)
            .background(fillColor, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1.2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nodeAccessibilityLabel(node))
    }

    // MARK: - Selected Node Footer

    private func selectedNodeFooter(stage: DrummerPathStageModel) -> some View {
        Group {
            if let node = focusedNode {
                let canPlay = node.state != .locked
                let ctaTitle = node.state == .completed
                    ? (language == .czech ? "Pokračovat" : "Continue")
                    : (language == .czech ? "Hrát" : "Play")

                HStack(spacing: Theme.Space.controlGap) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            if node.isBoss {
                                Text(language == .czech ? "ZKOUŠKA ETAPY · +1 KLÍČ" : "STAGE EXAM · +1 KEY")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.orange)
                            } else if node.isSideQuest {
                                Text(language == .czech ? "BOČNÍ VÝZVA · BONUS XP" : "SIDE QUEST · BONUS XP")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(kitAccentColor(for: stage.primaryKit.kitId))
                            }
                            Text(settings.localized(node.lesson.title))
                                .font(Theme.rowTitle)
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                        }

                        Text("\(node.lesson.targetBpm) BPM · \(node.requiredKit.name) · \(node.stars)/3 ★")
                            .font(Theme.caption.monospacedDigit())
                            .foregroundStyle(Theme.secondary)
                    }

                    Spacer(minLength: 8)

                    Button {
                        onPlayLesson(node.lesson)
                    } label: {
                        Text(ctaTitle)
                            .font(Theme.action)
                            .padding(.horizontal, 20)
                            .frame(minWidth: 120, minHeight: 44)
                    }
                    .buttonStyle(PadPrimaryButtonStyle())
                    .disabled(!canPlay)
                }
            }
        }
    }

    // MARK: - Topology Windowing & Geometry

    private func windowedNodes(for stage: DrummerPathStageModel) -> [DrummerPathNode] {
        let all = stage.nodes
        let maxNodes = 6
        guard all.count > maxNodes else { return all }

        // Keep first nodes + active window + boss node so every topology fits cleanly without scroll.
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
        let padX: CGFloat = 44
        let usableW = max(120, size.width - padX * 2)
        let midY = size.height * 0.5

        switch topology {
        case .straightLine:
            return (0..<count).map { i in
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                return CGPoint(x: padX + t * usableW, y: midY)
            }

        case .splitFork:
            guard count >= 5 else {
                return nodeCoordinates(nodes: nodes, topology: .straightLine, in: size)
            }
            let topY = size.height * 0.28
            let botY = size.height * 0.72
            return (0..<count).map { i in
                if i == 0 {
                    return CGPoint(x: padX, y: midY)
                } else if i == 1 {
                    return CGPoint(x: padX + usableW * 0.22, y: midY)
                } else if i == count - 1 {
                    return CGPoint(x: padX + usableW, y: midY)
                } else {
                    let branch = nodes[i].branchTrack ?? 0
                    let middleTotal = max(1, (count - 3 + 1) / 2)
                    let col = (i - 2) / 2
                    let step = usableW * 0.46 / CGFloat(max(1, middleTotal))
                    let x = padX + usableW * 0.44 + CGFloat(col) * step
                    return CGPoint(x: x, y: branch == 0 ? topY : botY)
                }
            }

        case .stepSequencer:
            let cols = 3
            let row0Y = size.height * 0.30
            let row1Y = size.height * 0.72
            return (0..<count).map { i in
                let row = i / cols
                let rawCol = i % cols
                // Snake order: row 0 goes left->right, row 1 goes right->left.
                let col = (row % 2 == 0) ? rawCol : (cols - 1 - rawCol)
                let x = padX + (CGFloat(col) / CGFloat(max(1, cols - 1))) * usableW
                let y = row == 0 ? row0Y : row1Y
                return CGPoint(x: x, y: y)
            }

        case .loopWithSideQuest:
            let mainNodes = nodes.filter { !$0.isSideQuest }
            let mainCount = mainNodes.count
            var mainIndexById: [Int: Int] = [:]
            for (mIdx, node) in mainNodes.enumerated() {
                mainIndexById[node.id] = mIdx
            }
            let mainY = size.height * 0.36
            let sideY = size.height * 0.76
            return nodes.map { node in
                if node.isSideQuest {
                    return CGPoint(x: padX + usableW * 0.60, y: sideY)
                }
                let mIdx = mainIndexById[node.id] ?? 0
                let t = mainCount <= 1 ? 0.5 : CGFloat(mIdx) / CGFloat(mainCount - 1)
                return CGPoint(x: padX + t * usableW, y: mainY)
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

    private func kitAccentColor(for kitId: String) -> Color {
        switch kitId {
        case "acoustic": return Theme.orange
        case "rock": return Color(red: 224/255, green: 109/255, blue: 59/255)
        case "808": return Color(red: 59/255, green: 163/255, blue: 224/255)
        case "house": return Color(red: 78/255, green: 205/255, blue: 196/255)
        case "jazz": return Color(red: 212/255, green: 168/255, blue: 67/255)
        case "brush": return Color(red: 149/255, green: 184/255, blue: 120/255)
        case "world", "worldperc": return Color(red: 201/255, green: 122/255, blue: 64/255)
        default: return Theme.orange
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
