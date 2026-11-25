//
//  SettingsManager+Library.swift
//  SmackAPad
//

import Foundation

// MARK: - Hidden Categories, Memory Hints & Lesson Kit Overrides

extension SettingsManager {
    // MARK: Hidden Categories

    public func hiddenCategories(for mode: String) -> Set<String> {
        withLock { hiddenCategoryIDsByMode[mode] ?? [] }
    }

    public func hideCategory(_ id: String, in mode: String) {
        withLock {
            var current = hiddenCategoryIDsByMode[mode] ?? []
            current.insert(id)
            hiddenCategoryIDsByMode[mode] = current
        }
    }

    public func unhideCategory(_ id: String, in mode: String) {
        withLock {
            var current = hiddenCategoryIDsByMode[mode] ?? []
            current.remove(id)
            hiddenCategoryIDsByMode[mode] = current
        }
    }

    public func isCategoryHidden(_ id: String, in mode: String) -> Bool {
        withLock { hiddenCategoryIDsByMode[mode]?.contains(id) ?? false }
    }

    func persistHiddenCategories() {
        withLock {
            for mode in ["path", "genre", "technique"] {
                let ids = Array(hiddenCategoryIDsByMode[mode] ?? []).sorted()
                userDefaults.set(ids, forKey: "smackapad.library.hiddenCategories.\(mode)")
            }
        }
    }

    // MARK: Memory Star Hint

    public func hasShownMemoryHint(for lessonId: Int) -> Bool {
        withLock { memoryHintShownIds().contains(lessonId) }
    }

    public func markMemoryHintShown(for lessonId: Int) {
        withLock {
            var set = memoryHintShownIds()
            set.insert(lessonId)
            if let data = try? JSONEncoder().encode(Array(set)) {
                userDefaults.set(data, forKey: "smackapad.memoryHintShownLessonIds")
            }
        }
    }

    private func memoryHintShownIds() -> Set<Int> {
        guard let data = userDefaults.data(forKey: "smackapad.memoryHintShownLessonIds"),
              let ids = try? JSONDecoder().decode([Int].self, from: data) else { return [] }
        return Set(ids)
    }

    // MARK: Lesson Kit Override Management

    /// Returns any sound kit override set for the given lesson ID, or nil if none.
    public func kitOverride(for lessonId: Int) -> String? {
        withLock { lessonKitOverrides[lessonId] }
    }

    /// Sets or clears a sound kit override for a lesson.
    /// Setting "auto", empty, or nil removes the override.
    public func setKitOverride(_ kitId: String?, for lessonId: Int) {
        withLock {
            var updated = lessonKitOverrides
            if let kitId = kitId, kitId != "auto" && !kitId.isEmpty {
                updated[lessonId] = kitId
            } else {
                updated.removeValue(forKey: lessonId)
            }
            self.lessonKitOverrides = updated
        }
    }

    func persistKitId() {
        withLock {
            userDefaults.set(selectedKitId, forKey: SettingsKey.selectedKitId.rawValue)
        }
    }

    func persistLessonKitOverrides() {
        withLock {
            if let data = try? JSONEncoder().encode(lessonKitOverrides) {
                userDefaults.set(data, forKey: SettingsKey.lessonKitOverrides.rawValue)
            }
        }
    }
}
