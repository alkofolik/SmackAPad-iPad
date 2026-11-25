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
                    .frame(maxHeight: .infinity)

                selectedNodeFooter(stage: stage)
            }
        }
        .padding(Theme.Space.regular)
        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.5)
        }
        .shadow(color: Color.black.opacity(0.32), radius: 8, y: 3)
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
                        .foregroundStyle(isSelected ? Color.black : Color.white)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(
                            isSelected ? accent : Color(red: 0.047, green: 0.047, blue: 0.055),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.button)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                .strokeBorder(isSelected ? accent : Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.2)
                        }
                        .shadow(color: isSelected ? accent.opacity(0.35) : .clear, radius: 5)
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

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                    .shadow(color: accent.opacity(0.8), radius: 4)
                Text(stage.topology.title(language: language).uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.75))

                Text("·")
                    .foregroundStyle(Color.white.opacity(0.35))

                Text(stage.primaryKit.name.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(accent)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: stage.isExamCompleted ? "checkmark.seal.fill" : "key.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.orange)
                    Text(stage.isExamCompleted
                         ? (language == .czech ? "Zkouška splněna" : "Exam passed")
                         : (language == .czech ? "Zkouška etapy = +1 KEY" : "Stage exam = +1 KEY"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(stage.isExamCompleted ? Theme.orange : Color.white.opacity(0.78))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06), in: Capsule())
            }

            GeometryReader { geo in
                let displayNodes = windowedNodes(for: stage)
                let points = nodeCoordinates(
                    nodes: displayNodes,
                    topology: stage.topology,
                    in: geo.size
                )

                ZStack {
                    rackGridBackground

                    patchCableLayer(nodes: displayNodes, points: points, topology: stage.topology, accent: accent)

                    ForEach(Array(displayNodes.enumerated()), id: \.element.id) { idx, node in
                        if idx < points.count {
                            nodeButton(node: node, stage: stage, accent: accent)
                                .position(points[idx])
                        }
                    }
                }
            }
            .frame(minHeight: 270, maxHeight: .infinity)
        }
        .padding(Theme.Space.regular)
        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.25)
        }
    }

    private var rackGridBackground: some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            for x in stride(from: spacing, to: size.width, by: spacing) {
                for y in stride(from: spacing, to: size.height, by: spacing) {
                    let dot = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                    context.fill(Path(ellipseIn: dot), with: .color(Color.white.opacity(0.06)))
                }
            }
        }
        .allowsHitTesting(false)
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

                // Dark outer cable sleeve
                context.stroke(
                    path,
                    with: .color(Color.black.opacity(0.8)),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )

                let strokeColor: Color = if isActiveLink {
                    Theme.orange
                } else if isLit {
                    accent
                } else {
                    Color(red: 0.20, green: 0.20, blue: 0.24)
                }

                if isActiveLink || isLit {
                    var glowContext = context
                    glowContext.addFilter(.shadow(color: strokeColor.opacity(0.75), radius: 6, x: 0, y: 0))
                    glowContext.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: isActiveLink ? 4.5 : 3.5, lineCap: .round)
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 5])
                    )
                }

                // Jack sockets at endpoints
                for endpoint in [start, end] {
                    let socket = CGRect(x: endpoint.x - 4, y: endpoint.y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: socket), with: .color(strokeColor))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func bossRewardTitle(for stage: DrummerPathStageModel) -> String {
        if let lockedKit = stage.lockedKit {
            return lockedKit.name
        }
        if let track = StudioRigCatalog.bonusTracks.first(where: {
            if case .anyStageExamInLevel(let lvl) = $0.unlockRequirement { return lvl == stage.level }
            return false
        }) {
            return track.title
        }
        return stage.primaryKit.name
    }

    private func nodeButton(node: DrummerPathNode, stage: DrummerPathStageModel, accent: Color) -> some View {
        let isFocused = focusedNode?.id == node.id
        let isCompleted = node.state == .completed
        let isActive = node.state == .active
        let isLocked = node.state == .locked

        let borderColor: Color = if isFocused || isActive {
            Theme.orange
        } else if node.isBoss {
            Theme.orange.opacity(isLocked ? 0.45 : 0.9)
        } else if isCompleted {
            accent.opacity(0.9)
        } else {
            Color(red: 0.204, green: 0.204, blue: 0.239)
        }

        let fillColor: Color = if isActive {
            Color(red: 0.16, green: 0.10, blue: 0.06)
        } else if node.isBoss {
            Color(red: 0.13, green: 0.11, blue: 0.09)
        } else if isCompleted {
            Color(red: 0.118, green: 0.118, blue: 0.141)
        } else {
            Color(red: 0.078, green: 0.078, blue: 0.090)
        }

        let nodeWidth: CGFloat = node.isBoss ? 128 : 104
        let nodeHeight: CGFloat = node.isBoss ? 88 : 74
        let titleText = settings.localized(node.lesson.title)

        return Button {
            selectedNodeId = node.id
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    if node.isBoss {
                        Image(systemName: "key.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.orange)
                    } else if node.isSideQuest {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                    } else if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.38))
                    } else {
                        Circle()
                            .fill(Theme.orange)
                            .frame(width: 6, height: 6)
                    }

                    Text(node.isBoss ? "BOSS" : (node.isSideQuest ? "SIDE" : String(format: "%02d", node.orderIndex + 1)))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(node.isBoss ? Theme.orange : (isLocked ? Color.white.opacity(0.45) : Color.white.opacity(0.75)))

                    Spacer(minLength: 2)

                    HStack(spacing: 1.5) {
                        ForEach(0..<3, id: \.self) { starIdx in
                            Image(systemName: starIdx < node.stars ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(starIdx < node.stars ? Theme.orange : Color.white.opacity(0.22))
                        }
                    }
                }

                Text(titleText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isLocked ? Color.white.opacity(0.48) : Color.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                if node.isBoss {
                    HStack(spacing: 4) {
                        Text("+1 KEY")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Theme.orange, in: RoundedRectangle(cornerRadius: 3))
                        Text(bossRewardTitle(for: stage))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(width: nodeWidth, height: nodeHeight)
            .background(fillColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused || isActive ? 2 : 1.25)
            }
            .shadow(color: (isActive || isFocused) ? Theme.orange.opacity(0.35) : Color.black.opacity(0.45), radius: isActive || isFocused ? 8 : 4, y: 2)
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
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            if node.isBoss {
                                Text(language == .czech ? "ZKOUŠKA ETAPY · +1 KEY" : "STAGE EXAM · +1 KEY")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.orange)
                            } else if node.isSideQuest {
                                Text(language == .czech ? "BOČNÍ VÝZVA · BONUS XP" : "SIDE QUEST · BONUS XP")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(kitAccentColor(for: stage.primaryKit.kitId))
                            }
                            Text(settings.localized(node.lesson.title))
                                .font(Theme.rowTitle)
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                        }

                        Text("\(node.lesson.targetBpm) BPM · \(node.requiredKit.name) · \(node.stars)/3 ★")
                            .font(Theme.caption.monospacedDigit())
                            .foregroundStyle(Color.white.opacity(0.65))
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
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Topology Windowing & Geometry

    private func windowedNodes(for stage: DrummerPathStageModel) -> [DrummerPathNode] {
        let all = stage.nodes
        let maxNodes = 5
        guard all.count > maxNodes else { return all }

        // Keep first nodes + active window + boss node so every topology fits cleanly with roomy nodes.
        let activeIdx = all.firstIndex(where: { $0.state == .active }) ?? 0
        let start = max(0, min(activeIdx - 1, all.count - maxNodes))
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
        let padLeading: CGFloat = 58
        let padTrailing: CGFloat = 70
        let usableW = max(120, size.width - padLeading - padTrailing)
        let midY = size.height * 0.5

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
            let topY = size.height * 0.25
            let botY = size.height * 0.75
            return (0..<count).map { i in
                if i == 0 {
                    return CGPoint(x: padLeading, y: midY)
                } else if i == 1 {
                    return CGPoint(x: padLeading + usableW * 0.24, y: midY)
                } else if i == count - 1 {
                    return CGPoint(x: padLeading + usableW, y: midY)
                } else {
                    let branch = nodes[i].branchTrack ?? 0
                    let middleTotal = max(1, (count - 3 + 1) / 2)
                    let col = (i - 2) / 2
                    let step = usableW * 0.44 / CGFloat(max(1, middleTotal))
                    let x = padLeading + usableW * 0.48 + CGFloat(col) * step
                    return CGPoint(x: x, y: branch == 0 ? topY : botY)
                }
            }

        case .stepSequencer:
            let cols = 3
            let row0Y = size.height * 0.27
            let row1Y = size.height * 0.73
            return (0..<count).map { i in
                let row = i / cols
                let rawCol = i % cols
                // Snake order: row 0 goes left->right, row 1 goes right->left.
                let col = (row % 2 == 0) ? rawCol : (cols - 1 - rawCol)
                let x = padLeading + (CGFloat(col) / CGFloat(max(1, cols - 1))) * usableW
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
            let mainY = size.height * 0.30
            let sideY = size.height * 0.76
            return nodes.map { node in
                if node.isSideQuest {
                    return CGPoint(x: padLeading + usableW * 0.62, y: sideY)
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
