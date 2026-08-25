import Foundation
import XCTest
@testable import GoogleYuepinCore

final class CandidateCacheTests: XCTestCase {
    func testStoresReadsAndExpiresCandidates() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = try CandidateCache(
            path: directory.appendingPathComponent("cache.sqlite3"),
            lifetime: 60
        )
        let initialDate = Date(timeIntervalSince1970: 1_000)
        let candidates = [Candidate(text: "你", annotation: "nei", matchedLength: 3)]

        try await cache.store(candidates, for: "nei", now: initialDate)
        let fresh = try await cache.candidates(
            for: "nei",
            now: Date(timeIntervalSince1970: 1_030)
        )
        XCTAssertEqual(fresh, candidates)

        let expired = try await cache.candidates(
            for: "nei",
            now: Date(timeIntervalSince1970: 1_061)
        )
        XCTAssertNil(expired)

        let stale = try await cache.candidates(
            for: "nei",
            allowExpired: true,
            now: Date(timeIntervalSince1970: 1_061)
        )
        XCTAssertEqual(stale, candidates)
    }
}
