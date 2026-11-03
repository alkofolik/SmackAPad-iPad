import Darwin
import Foundation

/// Temporary diagnostic logger for Ticket 54 (Bluetooth MIDI timing).
public final class BluetoothTimingDiagnostics: @unchecked Sendable {
    public static let shared = BluetoothTimingDiagnostics()

    public var enabled = true

    private let fileQueue = DispatchQueue(label: "cz.kju.SmackAPad.BluetoothTimingDiagnostics")
    private var currentFileURL: URL?
    private var currentHandle: FileHandle?
    private let timebaseRatio: Double

    private init() {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        timebaseRatio = Double(timebase.numer) / Double(timebase.denom)
    }

    public func startRun(lessonId: Int, bpm: Int) {
        guard enabled else { return }
        fileQueue.async {
            self.stopCurrentHandle()
            let fileManager = FileManager.default
            guard let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

            let filePrefix = "bluetooth-timing-"
            let fileExtension = "txt"

            // Keep at most 5 files: delete oldest beyond 4 before creating a new one
            if let urls = try? fileManager.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: [.creationDateKey]) {
                let existing = urls.filter {
                    $0.lastPathComponent.hasPrefix(filePrefix) && $0.pathExtension == fileExtension
                }.sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
                if existing.count >= 5 {
                    for oldURL in existing[4...] {
                        try? fileManager.removeItem(at: oldURL)
                    }
                }
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestampString = formatter.string(from: Date())
            let fileURL = docsDir.appendingPathComponent("\(filePrefix)\(timestampString).\(fileExtension)")

            fileManager.createFile(atPath: fileURL.path, contents: nil)
            guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
            self.currentFileURL = fileURL
            self.currentHandle = handle

            let header = """
            === Smack-a-Pad Bluetooth Timing Diagnostic Log ===
            Started: \(Date())
            Lesson: \(lessonId)
            Start BPM: \(bpm)
            Mach timebase: \(self.timebaseRatio) ns/tick
            --------------------------------------------------\n
            """
            self.write(header)
        }
    }

    public func logPass(number: Int, startSeconds: Double, hostTime: UInt64, bpm: Int) {
        guard enabled else { return }
        fileQueue.async {
            let line = String(
                format: "[PASS %d] start=%.6fs hostTime=%llu bpm=%d\n",
                number, startSeconds, hostTime, bpm
            )
            self.write(line)
        }
    }

    public func logNoteOn(
        deviceID: String,
        rawTimestamp: UInt64,
        receiptTimestamp: UInt64,
        resolvedTimestamp: UInt64,
        usedReceiptTime: Bool,
        expectedStep: Int?,
        timingErrorMs: Double?,
        timingCenterMs: Double?,
        passNumber: Int
    ) {
        guard enabled else { return }
        fileQueue.async {
            let stepStr = expectedStep.map(String.init) ?? "none"
            let errorStr = timingErrorMs.map { String(format: "%+.2fms", $0) } ?? "none"
            let centerStr = timingCenterMs.map { String(format: "%+.2fms", $0) } ?? "0.00ms"

            let diffTicks: Int64
            if rawTimestamp >= receiptTimestamp {
                diffTicks = Int64(rawTimestamp - receiptTimestamp)
            } else {
                diffTicks = -Int64(receiptTimestamp - rawTimestamp)
            }
            let diffMs = Double(diffTicks) * self.timebaseRatio / 1_000_000.0

            let line = String(
                format: "[NOTE-ON] dev=%@ pass=%d raw=%llu receipt=%llu res=%llu usedReceipt=%@ rawMinusReceipt=%+.2fms step=%@ err=%@ center=%@\n",
                deviceID, passNumber, rawTimestamp, receiptTimestamp, resolvedTimestamp,
                usedReceiptTime ? "true" : "false", diffMs, stepStr, errorStr, centerStr
            )
            self.write(line)
        }
    }

    public func stopRun() {
        guard enabled else { return }
        fileQueue.async {
            self.write("--- Run ended at \(Date()) ---\n")
            self.stopCurrentHandle()
        }
    }

    private func write(_ string: String) {
        guard let handle = currentHandle, let data = string.data(using: .utf8) else { return }
        try? handle.write(contentsOf: data)
        try? handle.synchronize()
    }

    private func stopCurrentHandle() {
        try? currentHandle?.synchronize()
        try? currentHandle?.close()
        currentHandle = nil
        currentFileURL = nil
    }
}
