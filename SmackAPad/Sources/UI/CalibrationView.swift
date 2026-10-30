import SwiftUI

@MainActor
struct CalibrationView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: CalibrationSession
    @State private var touching = false
    let settings: SettingsManager
    let midi: MIDIInput

    init(settings: SettingsManager, midi: MIDIInput) {
        self.settings = settings
        self.midi = midi
        _session = State(initialValue: CalibrationSession(settings: settings, midi: midi))
    }

    var body: some View {
        @Bindable var session = session
        Form {
            Section {
                Picker("Calibration input", selection: $session.deviceID) {
                    Text("On-screen pads").tag("touch")
                    ForEach(midi.sources) { source in Text(source.name).tag(source.id) }
                }
                .disabled(session.busy)
                LabeledContent("Saved offset", value: signed(settings.calibrationOffset(for: session.deviceID)))
                Text("Listen to four clicks, then tap with each of the next ten. Follow the sound, not the screen.")
            }

            Section("Calibration progress") {
                Text(status).font(.title2).accessibilityAddTraits(.updatesFrequently)
                if session.busy {
                    ProgressView(value: Double(session.matchedClicks.count), total: 10)
                    LabeledContent("Recorded taps", value: "\(session.matchedClicks.count) / 10")
                }
                if session.deviceID == "touch" {
                    Text("Tap with the click")
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 140)
                        .background(touching ? Color.orange.opacity(0.25) : Color.secondary.opacity(0.1))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard !touching else { return }
                                touching = true
                                session.touch()
                            }
                            .onEnded { _ in touching = false })
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { session.touch() }
                }
                if let result = session.result {
                    LabeledContent("Saved offset", value: signed(result.offsetMilliseconds))
                    LabeledContent("Usable taps", value: "\(result.usableTaps) / 10")
                    LabeledContent("Timing spread", value: "\(Int(result.spreadMilliseconds.rounded())) ms")
                    if result.discardedTaps > 0 { Text("Outlier taps were ignored.") }
                    Text("Play a lesson to check the result.")
                }
                if let error = session.audioError { Text(error).foregroundStyle(.secondary) }
                if session.busy {
                    Button("Cancel calibration", role: .cancel) { session.cancel() }
                } else {
                    Button("Start calibration") { touching = false; session.start() }
                }
            }
        }
        .navigationTitle("Timing calibration")
        .onAppear { session.attach() }
        .onDisappear { session.close() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { session.cancel() } }
        .onChange(of: midi.sources) { _, sources in
            if !session.busy, session.deviceID != "touch", !sources.contains(where: { $0.id == session.deviceID }) {
                session.deviceID = "touch"
            }
        }
    }

    private func signed(_ value: Double) -> String { String(format: "%+.0f ms", value) }

    private var status: LocalizedStringKey {
        switch session.phase {
        case .idle: return "Ready. Choose an input and start."
        case .preparing: return "Preparing audio…"
        case .countIn: return "Listen first · \(max(1, session.clickNumber)) / 4"
        case .measuring: return "Tap with the sound · \(session.clickNumber) / 10"
        case .completed: return "Calibration saved."
        case .cancelled: return "Calibration cancelled. Previous settings kept."
        case .failed:
            switch session.failure {
            case .tooFewTaps: return "Too few taps. Record at least six of ten clicks. Previous settings kept."
            case .unevenTaps: return "Taps were too uneven. Follow the sound and try again. Previous settings kept."
            case .audioClockChanged: return "Audio timing changed or is not ready. Try again. Previous settings kept."
            case nil: return "Audio could not start. Try again. Previous settings kept."
            }
        }
    }
}
