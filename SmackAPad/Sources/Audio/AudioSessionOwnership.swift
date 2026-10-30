import Foundation

/// Serializes app-wide session activation. Each engine has one stable owner ID.
/// A stopped engine may deactivate the session only when no other engine owns it.
public final class AudioSessionOwnership: @unchecked Sendable {
    private let lock = NSLock()
    private var owners: Set<UUID> = []
    private let activate: () throws -> Void
    private let deactivate: () throws -> Void

    public init(activate: @escaping () throws -> Void, deactivate: @escaping () throws -> Void) {
        self.activate = activate
        self.deactivate = deactivate
    }

    public func acquire(for owner: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        // Reassert activation on restart/resume: a system interruption can make the
        // session inactive without removing an engine's playback intent.
        try activate()
        owners.insert(owner)
    }

    public func release(for owner: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        guard owners.remove(owner) != nil, owners.isEmpty else { return }
        try deactivate()
    }
}
