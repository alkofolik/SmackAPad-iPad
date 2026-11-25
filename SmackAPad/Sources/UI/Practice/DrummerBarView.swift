import SwiftUI

/// Compact top hardware strip showing Drummer Level, Rank, XP bar, 4 attributes, and Keys -> Studio Rig.
@MainActor
struct DrummerBarView: View {
    @Environment(SettingsManager.self) private var settings

    let card: DrummerCardSnapshot
    let availableKeys: Int
    let isCompact: Bool
    let onOpenStudioRig: () -> Void

    private var language: AppLanguage { settings.languagePreference }

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    HStack(spacing: Theme.Space.controlGap) {
                        levelAndRankBlock
                        Spacer(minLength: 8)
                        keysButton
                    }
                    attributesRow
                }
            } else {
                HStack(spacing: Theme.Space.regular) {
                    levelAndRankBlock
                        .frame(minWidth: 210, maxWidth: 260, alignment: .leading)

                    hardwareDivider

                    attributesRow
                        .frame(maxWidth: .infinity)

                    hardwareDivider

                    keysButton
                }
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, 10)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var hardwareDivider: some View {
        Rectangle()
            .fill(Theme.white.opacity(0.12))
            .frame(width: 1, height: 32)
            .accessibilityHidden(true)
    }

    private var levelAndRankBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text("LVL \(card.level)")
                    .font(Theme.strong(13).monospacedDigit())
                    .foregroundStyle(Theme.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 4))

                Text(card.rank.title)
                    .font(Theme.strong(15))
                    .foregroundStyle(Theme.white)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.white.opacity(0.14))
                        Capsule()
                            .fill(Theme.orange)
                            .frame(width: max(4, geo.size.width * card.levelProgress))
                    }
                }
                .frame(height: 4)

                Text("\(card.xp)/\(card.nextLevelXP) XP")
                    .font(Theme.caption.monospacedDigit())
                    .foregroundStyle(Theme.white.opacity(0.62))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(card.level), \(card.rank.title), \(card.xp) / \(card.nextLevelXP) XP")
    }

    private var attributesRow: some View {
        HStack(spacing: Theme.Space.controlGap) {
            ForEach(DrummerAttribute.allCases) { attr in
                let value = card.attributes[attr]
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(attr.code)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.white.opacity(0.58))
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text("\(value)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.white)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.white.opacity(0.12))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(value > 0 ? Theme.orange.opacity(0.88) : Color.clear)
                                .frame(width: geo.size.width * CGFloat(value) / 100.0)
                        }
                    }
                    .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(attr.title(language: language)) \(value)")
            }
        }
    }

    private var keysButton: some View {
        Button(action: onOpenStudioRig) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(availableKeys > 0 ? Theme.orange : Theme.white.opacity(0.55))

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(availableKeys) \(keysUnit(availableKeys))")
                        .font(Theme.strong(14).monospacedDigit())
                        .foregroundStyle(Theme.white)
                    Text("Studio Rig")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.white.opacity(0.6))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.white.opacity(0.45))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minHeight: 40)
            .background(Theme.white.opacity(0.07), in: RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .strokeBorder(availableKeys > 0 ? Theme.orange.opacity(0.55) : Theme.white.opacity(0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(availableKeys) \(keysUnit(availableKeys)), Studio Rig")
    }

    private func keysUnit(_ count: Int) -> String {
        switch language {
        case .czech:
            if count == 1 { return "klíč" }
            if (2...4).contains(count) { return "klíče" }
            return "klíčů"
        case .english:
            return count == 1 ? "key" : "keys"
        }
    }
}

/// Quick Studio Rig sheet opened from the Drummer Bar keys button or a locked-kit banner.
@MainActor
struct StudioRigQuickSheet: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    let highlightedKitId: String?
    let onOpenLibrary: () -> Void

    private var language: AppLanguage { settings.languagePreference }
    private var availableKeys: Int { progress.drummerPath.availableKeys }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Studio Rig")
                                .font(Theme.screenTitle)
                                .foregroundStyle(Theme.ink)
                            Text(language == .czech
                                 ? "Odemkni další sady bicích pomocí klíčů ze zkoušek etap a milníků."
                                 : "Unlock drum kits using keys earned from stage exams and milestones.")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(Theme.orange)
                            Text("\(availableKeys)")
                                .font(Theme.strong(18).monospacedDigit())
                                .foregroundStyle(Theme.ink)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: Theme.Space.small)], spacing: Theme.Space.small) {
                        ForEach(DrumKitCatalog.allKits) { kit in
                            kitCard(kit)
                        }
                    }

                    Button {
                        dismiss()
                        onOpenLibrary()
                    } label: {
                        HStack {
                            Text(language == .czech ? "Otevřít knihovnu lekcí" : "Open Lesson Library")
                                .font(Theme.action)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .padding(.horizontal, Theme.Space.regular)
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
                .padding(Theme.Space.page)
            }
            .calmChassisBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .czech ? "Hotovo" : "Done") { dismiss() }
                }
            }
        }
    }

    private func kitCard(_ kit: DrumKitDescriptor) -> some View {
        let unlocked = progress.drummerPath.isKitUnlocked(kit.kitId)
        let isHighlighted = kit.kitId == highlightedKitId
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(kit.name)
                    .font(Theme.rowTitle)
                    .foregroundStyle(Theme.ink)
                Spacer()
                if unlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.orange)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.secondary)
                }
            }

            Text(kit.studioTitle)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)

            if unlocked {
                Text(language == .czech ? "Odemčeno" : "Unlocked")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Theme.orange)
            } else {
                Button {
                    _ = progress.unlockKit(kit.kitId)
                } label: {
                    Text(language == .czech ? "Odemknout (1 klíč)" : "Unlock (1 key)")
                        .font(Theme.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .disabled(availableKeys < kit.unlockCost)
            }
        }
        .padding(Theme.Space.controlGap)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(isHighlighted ? Theme.orange : Theme.hairline, lineWidth: isHighlighted ? 1.5 : 1)
        }
    }
}
