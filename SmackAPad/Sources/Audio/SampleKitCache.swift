/// Used only on the sample loader queue. The engine keeps its own reference
/// to the selected buffers until playback switches kits.
struct SampleKitCache<Kit> {
    private var cached: (id: String, kit: Kit)?

    mutating func load(
        _ id: String, fallback: String, decode: (String) throws -> Kit
    ) throws -> Kit {
        do {
            return try load(id, decode: decode)
        } catch where id != fallback {
            return try load(fallback, decode: decode)
        }
    }

    private mutating func load(_ id: String, decode: (String) throws -> Kit) throws -> Kit {
        if let cached, cached.id == id { return cached.kit }
        let kit = try decode(id)
        cached = (id, kit)
        return kit
    }
}
