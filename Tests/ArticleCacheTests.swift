import XCTest
@testable import Articles

final class ArticleCacheTests: XCTestCase {
    func testDiskCacheSurvivesASecondStorageInstance() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try ArticleCache(name: "PersistenceTest", directory: directory)
        let snapshot = ArticleSnapshot(articles: [Article(title: "Offline story")], savedAt: Date(timeIntervalSince1970: 1))
        try await first.write(snapshot)
        let second = try ArticleCache(name: "PersistenceTest", directory: directory)
        let restored = try await second.read()
        XCTAssertEqual(restored, snapshot)
    }
    func testAbsentDiskEntryIsNotAnError() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = try ArticleCache(name: "AbsentTest", directory: directory)
        let snapshot = try await cache.read()
        XCTAssertNil(snapshot)
    }
}
