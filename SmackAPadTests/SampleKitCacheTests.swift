import XCTest
@testable import SmackAPad

final class SampleKitCacheTests: XCTestCase {
    func testLoadsOnlyTheRequestedKit() throws {
        var cache = SampleKitCache<String>()
        var decoded: [String] = []
        let kit = try cache.load("rock", fallback: "acoustic") { id in
            decoded.append(id)
            return id
        }
        XCTAssertEqual(kit, "rock")
        XCTAssertEqual(decoded, ["rock"])
    }

    func testReusesAnAlreadyLoadedKit() throws {
        var cache = SampleKitCache<String>()
        var decoded: [String] = []
        let decode: (String) -> String = { id in
            decoded.append(id)
            return id
        }
        _ = try cache.load("808", fallback: "acoustic", decode: decode)
        let kit = try cache.load("808", fallback: "acoustic", decode: decode)
        XCTAssertEqual(kit, "808")
        XCTAssertEqual(decoded, ["808"])
    }

    func testFallsBackToAcousticIfTheSelectedKitFails() throws {
        var cache = SampleKitCache<String>()
        var decoded: [String] = []
        let kit = try cache.load("jazz", fallback: "acoustic") { id in
            decoded.append(id)
            if id == "jazz" { throw CocoaError(.fileReadCorruptFile) }
            return id
        }
        XCTAssertEqual(kit, "acoustic")
        XCTAssertEqual(decoded, ["jazz", "acoustic"])
    }
}
