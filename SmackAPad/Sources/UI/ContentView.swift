import CoreAudioKit
import SwiftUI

@MainActor
struct MIDISettingsView: View {
    var body: some View {
        SettingsView()
    }
}

@MainActor
struct MIDILearnView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss
    @State private var padCount = 16
    @State private var profileName = ""

    private var czech: Bool { settings.languagePreference == .czech }
    private func label(_ cs: String, _ en: String) -> String { czech ? cs : en }

    private var trimmedName: String { profileName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameExists: Bool { settings.profile(named: trimmedName) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(label("Nový profil kontroléru", "New controller profile")) {
                    TextField(label("Název profilu", "Profile name"), text: $profileName)
                        .font(Theme.text())
                    Picker(label("Počet padů", "Pad count"), selection: $padCount) {
                        Text(label("8 padů", "8 pads")).tag(8)
                        Text(label("16 padů", "16 pads")).tag(16)
                    }
                    .pickerStyle(.segmented)
                    .disabled(midi.isLearning)

                    if nameExists {
                        Text(label("Profil s tímto názvem už existuje.", "This profile name is already in use."))
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.markWrong)
                    }
                }

                Section {
                    if midi.isLearning {
                        LabeledContent(label("Naučené pady", "Learned pads"), value: "\(midi.learnedNotes.count) / \(padCount)")
                            .font(Theme.text())

                        if midi.learningComplete {
                            Text(label("Všechny pady jsou naučené. Ulož profil a můžeš ho používat.",
                                       "All pads learned. Save the profile to use it."))
                                .font(Theme.text(Theme.Size.small))
                                .foregroundStyle(Theme.markCorrect)
                        } else {
                            Text(label("Stiskni zvýrazněný pad na svém kontroléru.",
                                       "Press the highlighted pad on your controller."))
                                .font(Theme.text(Theme.Size.small))
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.small), count: 4), spacing: Theme.Space.small) {
                            ForEach(0..<padCount, id: \.self) { slot in
                                VStack(spacing: Theme.Space.tight) {
                                    Text(label("Pad \(slot + 1)", "Pad \(slot + 1)"))
                                        .font(Theme.display(Theme.Size.small))
                                    if midi.learnedNotes.indices.contains(slot) {
                                        Text(midi.learnedNotes[slot].formatted())
                                            .font(Theme.text(Theme.Size.small))
                                            .monospacedDigit()
                                    } else {
                                        Text("—")
                                            .font(Theme.text(Theme.Size.small))
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(slot == midi.learnedNotes.count ? Theme.orange.opacity(0.3) : Theme.surface,
                                            in: RoundedRectangle(cornerRadius: Theme.Size.blockRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                                        .stroke(slot == midi.learnedNotes.count ? Theme.orange : Color.clear, lineWidth: Theme.Size.border)
                                )
                                .accessibilityAddTraits(slot == midi.learnedNotes.count ? .isSelected : [])
                            }
                        }

                        if midi.learningNotice == "duplicateNote" {
                            Text(label("Tato nota už je přiřazená. Stiskni jiný pad.",
                                       "That note is already assigned. Press a different pad."))
                                .font(Theme.text(Theme.Size.small))
                                .foregroundStyle(Theme.markWrong)
                        }

                        Button(label("Začít znovu", "Start again")) {
                            midi.startLearning(padCount: padCount)
                        }
                        .font(Theme.text())
                        .frame(minHeight: Theme.Size.touch)
                    } else {
                        Button(label("Spustit učení MIDI", "Start MIDI learn")) {
                            midi.startLearning(padCount: padCount)
                        }
                        .font(Theme.text())
                        .frame(minHeight: Theme.Size.touch)
                        .disabled(midi.sources.isEmpty)

                        if midi.sources.isEmpty {
                            Text(label("Před spuštěním připoj MIDI kontrolér.",
                                       "Connect a MIDI controller before starting."))
                                .font(Theme.text(Theme.Size.small))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                } header: {
                    Text(label("UČENÍ MIDI", "MIDI LEARN"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    Text(label("Stiskni každý fyzický pad jednou, zleva doprava, od horní řady. Používej stále stejný kontrolér a MIDI kanál. V režimu 8 padů se učí pozice 1–8; zvuky určuje lekce.",
                               "Press each physical pad once, left to right, starting with the top row. Use the same controller and MIDI channel throughout. In 8-pad mode, positions are slots 1–8; sounds follow the lesson."))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .foregroundStyle(Theme.ink)
            .tint(Theme.orange)
            .navigationTitle(label("Učení MIDI", "MIDI learn"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(label("Zrušit", "Cancel")) { dismiss() }
                        .font(Theme.text())
                        .frame(minHeight: Theme.Size.touch)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(label("Uložit", "Save")) {
                        if midi.saveLearnedProfile(name: profileName) { dismiss() }
                    }
                    .font(Theme.text())
                    .frame(minHeight: Theme.Size.touch)
                    .disabled(!midi.learningComplete || trimmedName.isEmpty || nameExists)
                }
            }
            .onDisappear { midi.cancelLearning() }
        }
    }
}

struct TouchPad: View {
    let number: Int
    let sound: LocalizedStringKey
    let isActive: Bool
    let onPress: (Bool) -> Void
    @State private var isTouching = false

    var body: some View {
        VStack(spacing: Theme.Space.tight) {
            Text("Pad \(number)")
                .font(Theme.text(Theme.Size.dense))
                .foregroundStyle(Theme.secondary)
            Text(sound)
                .font(Theme.display(Theme.Size.small))
                .foregroundStyle(isActive ? Theme.orange : Theme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(isActive ? Theme.orange.opacity(0.3) : Theme.surface,
                    in: RoundedRectangle(cornerRadius: Theme.Size.blockRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                .stroke(isActive ? Theme.orange : Color.clear, lineWidth: Theme.Size.border)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isTouching else { return }
                    isTouching = true
                    onPress(true)
                }
                .onEnded { _ in release() }
        )
        .onDisappear { release() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPress(true); onPress(false) }
    }

    private func release() {
        guard isTouching else { return }
        isTouching = false
        onPress(false)
    }
}

enum PadNames {
    // Sound names for pad indices specified by the lesson layout.
    static func name(for padIndex: Int) -> LocalizedStringKey {
        switch padIndex {
        case 2: return "Crash"
        case 3: return "Ride"
        case 7: return "Open hi-hat"
        case 9: return "Clap"
        case 10: return "Rim"
        case 11: return "Hi-hat R"
        case 12: return "Kick L"
        case 13: return "Snare L"
        default: return "Pad \(padIndex + 1)"
        }
    }
}

/// Apple's pairing screen (CABTMIDICentralViewController) is a UIKit table controller.
/// It is presented from UIKit on the topmost controller, with the iOS 27 crash workaround below.
@MainActor
enum BluetoothMIDIPresenter {
    static func present() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first,
              var top = window.rootViewController else { return }
        while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
        let central = CABTMIDICentralViewController()
        // iOS 27 bug (Apple forums thread 850584, FB25301268): the controller's own
        // loadView builds its table with a NaN height and crashes. Supplying the table
        // first skips that code; viewDidLoad then starts Bluetooth discovery as usual.
        // Undocumented workaround from Apple DTS; remove once the minimum OS has the fix.
        if #available(iOS 27, *) {
            central.tableView = UITableView(frame: .zero, style: .grouped)
            central.viewDidLoad()
        }
        central.title = String(localized: "Bluetooth MIDI")
        let navigation = UINavigationController(rootViewController: central)
        navigation.modalPresentationStyle = .formSheet
        central.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak navigation] _ in navigation?.dismiss(animated: true) })
        top.present(navigation, animated: true)
    }
}

#Preview {
    SettingsView()
        .environment(SettingsManager.shared)
        .environment(MIDIInput(settings: .shared))
}
