import Foundation

public enum BackupStorage {
    public static var defaultBackupsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Backups", isDirectory: true)
    }

    /// Saves a pre-import safety snapshot of the given envelope to <Documents>/Backups/before-import-<timestamp>.json.
    /// Prunes to keep only the last 5.
    @discardableResult
    public static func createPreImportBackup(
        envelope: ProgressBackupEnvelope,
        directory: URL = defaultBackupsDirectory,
        date: Date = AppCalendar.now()
    ) throws -> URL {
        let manager = FileManager.default
        if !manager.fileExists(atPath: directory.path) {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: date)

        let prefix = "before-import-"
        let filename = "\(prefix)\(timestamp).json"
        let backupURL = directory.appendingPathComponent(filename)

        let data = try ProgressBackup.encode(envelope: envelope)
        try data.write(to: backupURL, options: .atomic)

        pruneBackups(prefix: prefix, keepCount: 5, in: directory)

        return backupURL
    }

    /// Saves a rolling daily backup to <Documents>/Backups/auto-<today>.json after the first earned star of the day.
    /// Prunes to keep only the last 3.
    @discardableResult
    public static func recordDailyAutoBackupIfNeeded(
        envelope: ProgressBackupEnvelope,
        today: String = AppCalendar.today(),
        directory: URL = defaultBackupsDirectory
    ) throws -> URL? {
        let manager = FileManager.default
        if !manager.fileExists(atPath: directory.path) {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let prefix = "auto-"
        let filename = "\(prefix)\(today).json"
        let backupURL = directory.appendingPathComponent(filename)

        if manager.fileExists(atPath: backupURL.path) {
            return nil
        }

        let data = try ProgressBackup.encode(envelope: envelope)
        try data.write(to: backupURL, options: .atomic)

        pruneBackups(prefix: prefix, keepCount: 3, in: directory)

        return backupURL
    }

    public static func pruneBackups(prefix: String, keepCount: Int, in directory: URL) {
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        let matching = files
            .filter { $0.lastPathComponent.hasPrefix(prefix) && $0.lastPathComponent.hasSuffix(".json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        if matching.count > keepCount {
            let toRemove = matching.prefix(matching.count - keepCount)
            for url in toRemove {
                try? manager.removeItem(at: url)
            }
        }
    }
}
