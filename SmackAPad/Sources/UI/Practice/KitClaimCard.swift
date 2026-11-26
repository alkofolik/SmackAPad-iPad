import SwiftUI

/// Post-victory kit claim card shown when a boss or exam victory awards a Tuning Key.
struct KitClaimCard: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress

    let victoryTitle: String
    let suggestedKit: DrumKitDescriptor?
    let onDone: () -> Void

    @State private var choosingAnotherKit = false

    private var language: AppLanguage { settings.languagePreference }

    private var availableKeys: Int { progress.drummerPath.availableKeys }

    private var lockedOtherKits: [DrumKitDescriptor] {
        DrumKitCatalog.allKits.filter { kit in
            !kit.isStarter
                && !progress.drummerPath.isKitUnlocked(kit.kitId)
                && kit.kitId != suggestedKit?.kitId
        }
    }

    private var canClaimSuggested: Bool {
        guard let suggestedKit else { return false }
        return !progress.drummerPath.isKitUnlocked(suggestedKit.kitId) && availableKeys >= 1
    }

    var body: some View {
        HardwareCard(padding: Theme.Space.regular) {
            if choosingAnotherKit {
                kitSelectorContent
            } else {
                claimSummaryContent
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var claimSummaryContent: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            HStack(alignment: .center, spacing: Theme.Space.small) {
                Text(victoryTitle)
                    .font(Theme.rowTitle)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: Theme.Space.small)

                keyBadge
            }

            if let suggestedKit {
                suggestedKitPanel(suggestedKit)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.small) { claimButtons }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: Theme.Space.small) { claimButtons }
            }
        }
    }

    private var keyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "key.fill")
                .font(.system(size: 12, weight: .bold))
            Text(language == .czech ? "+1 ladicí klíč" : "+1 Tuning Key")
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.accentGlow, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: 1)
        }
    }

    private func suggestedKitPanel(_ kit: DrumKitDescriptor) -> some View {
        let alreadyUnlocked = progress.drummerPath.isKitUnlocked(kit.kitId)
        return VStack(alignment: .leading, spacing: 4) {
            Text(language == .czech ? "DOPORUČENÝ NÁSTROJ" : "SUGGESTED INSTRUMENT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.secondary)

            HStack(alignment: .center, spacing: Theme.Space.small) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kit.name)
                        .font(Theme.strong(18))
                        .foregroundStyle(Theme.ink)
                    let epithet = kit.localizedClanEpithet(language: language)
                    if !epithet.isEmpty {
                        Text(epithet)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.secondary)
                    }
                }
                Spacer(minLength: Theme.Space.small)
                if alreadyUnlocked {
                    Text(language == .czech ? "Již odemčeno" : "Already unlocked")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
        .padding(Theme.Space.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var claimButtons: some View {
        if let suggestedKit, canClaimSuggested {
            Button(language == .czech ? "Vyzvednout nástroj" : "Claim instrument") {
                _ = progress.unlockKit(suggestedKit.kitId)
                onDone()
            }
            .buttonStyle(PadPrimaryButtonStyle())
        }

        if !lockedOtherKits.isEmpty || (suggestedKit != nil && !canClaimSuggested && availableKeys >= 1 && DrumKitCatalog.allKits.contains { !$0.isStarter && !progress.drummerPath.isKitUnlocked($0.kitId) }) {
            Button(language == .czech ? "Vybrat jinou sadu" : "Choose another kit") {
                choosingAnotherKit = true
            }
            .buttonStyle(PadSecondaryButtonStyle())
        }

        Button(language == .czech ? "Uložit klíč" : "Save key", action: onDone)
            .buttonStyle(PadSecondaryButtonStyle())
    }

    private var kitSelectorContent: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.small) {
                HardwareBackButton {
                    choosingAnotherKit = false
                }
                Text(language == .czech ? "Vybrat jinou sadu" : "Choose another kit")
                    .font(Theme.rowTitle)
                    .foregroundStyle(Theme.ink)
                Spacer()
                keyBadge
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(DrumKitCatalog.allKits.filter { !$0.isStarter }) { kit in
                        kitSelectorRow(kit)
                    }
                }
            }
            .frame(maxHeight: 240)
        }
    }

    private func kitSelectorRow(_ kit: DrumKitDescriptor) -> some View {
        let unlocked = progress.drummerPath.isKitUnlocked(kit.kitId)
        let canUnlock = !unlocked && availableKeys >= max(1, kit.unlockCost)
        let epithet = kit.localizedClanEpithet(language: language)

        return Button {
            guard canUnlock else { return }
            let result = progress.unlockKit(kit.kitId)
            if case .unlocked = result {
                onDone()
            }
        } label: {
            HStack(spacing: Theme.Space.small) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kit.name)
                        .font(Theme.strong(15))
                        .foregroundStyle(Theme.ink)
                    if !epithet.isEmpty {
                        Text(epithet)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.secondary)
                    }
                }
                Spacer(minLength: Theme.Space.small)
                if unlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text(language == .czech ? "Odemčeno" : "Unlocked")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.secondary)
                } else {
                    Text(language == .czech ? "Vyzvednout" : "Claim")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, Theme.Space.small)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(unlocked ? Theme.hairline : Theme.accent.opacity(0.5), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canUnlock)
        .opacity(unlocked ? 0.6 : 1)
    }
}
