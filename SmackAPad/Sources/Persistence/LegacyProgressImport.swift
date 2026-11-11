//
//  LegacyProgressImport.swift
//  SmackAPad
//

import Foundation

#if DEBUG
/// Only decodes the legacy fields needed for stars and tempo; all other data is ignored.
enum LegacyProgressImport {
    enum ImportError: Error { case invalidBackup }

    private struct Backup: Decodable {
        let app: String
        let formatVersion: Int
        let rewards: Rewards
        let progress: [String: Progress]?
    }
    private struct Rewards: Decodable { let stars: [String: Stars] }
    private struct Stars: Decodable {
        let passed: Bool?
        let mastered: Bool?
        let memory: String?
    }
    private struct Progress: Decodable {
        let bpm: Int?
        let best: Float?
    }

    static func map(_ data: Data) throws -> [Int: LessonProgress] {
        let backup: Backup
        do {
            backup = try JSONDecoder().decode(Backup.self, from: data)
        } catch {
            throw ImportError.invalidBackup
        }
        guard backup.app == "padwork", backup.formatVersion == 1 else {
            throw ImportError.invalidBackup
        }
        var records: [Int: LessonProgress] = [:]
        for (key, stars) in backup.rewards.stars {
            guard let id = Int(key), id > 0 else { throw ImportError.invalidBackup }
            let passed = stars.passed ?? false
            let mastery = stars.mastered ?? false
            let memory = stars.memory != nil
            guard passed || mastery || memory else { continue }
            let progress = backup.progress?[key]
            records[id] = LessonProgress(
                passed: passed, mastery: mastery, memory: memory, hasPlayed: true,
                currentBpm: max(0, progress?.bpm ?? 0),
                bestScore: min(1, max(0, (progress?.best ?? 0) / 100))
            )
        }
        ProgressStore.migrateDuplicateIntroProgress(in: &records)
        return records
    }

    static func merge(existing: [Int: LessonProgress], imported: [Int: LessonProgress]) -> [Int: LessonProgress] {
        var result = existing
        ProgressStore.migrateDuplicateIntroProgress(in: &result)
        for id in imported.keys.sorted() {
            guard let incoming = imported[id] else { continue }
            result[id] = ProgressStore.merging(result[id] ?? LessonProgress(), with: incoming)
        }
        return result
    }
}
#endif
