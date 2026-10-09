import XCTest
import XCGLogger
@testable import Articles

private final class ProviderStub: ArticleProviding {
    var result: Result<[Article], Error> = .success([Article(title: "New story")])
    var calls = 0
    var delay: UInt64 = 0
    func fetchArticles() async throws -> [Article] {
        calls += 1
        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        return try result.get()
    }
}
private actor CacheStub: ArticleCaching {
    var snapshot: ArticleSnapshot?
    var failWrite = false
    var failRead = false
    func read() async throws -> ArticleSnapshot? {
        if failRead { throw ArticleError.cacheUnavailable }
        return snapshot
    }
    func write(_ snapshot: ArticleSnapshot) async throws {
        if failWrite { throw ArticleError.cacheUnavailable }
        self.snapshot = snapshot
    }
    func seed(_ value: ArticleSnapshot?) { snapshot = value }
    func setFailWrite() { failWrite = true }
    func setFailRead() { failRead = true }
}
@MainActor private final class ConnectivityStub: ConnectivityMonitoring {
    var isOnline = true
    var onChange: ((Bool) -> Void)?
    func start() {}
    func change(_ value: Bool) { isOnline = value; onChange?(value) }
}

@MainActor final class ArticleManagerTests: XCTestCase {
    private var provider: ProviderStub!
    private var cache: CacheStub!
    private var connectivity: ConnectivityStub!
    private var defaults: UserDefaults!
    private var suite: String!
    private var manager: ArticleManager!
    private let saved = ArticleSnapshot(articles: [Article(title: "Saved story")], savedAt: Date(timeIntervalSince1970: 100))

    override func setUp() async throws {
        provider = ProviderStub(); cache = CacheStub(); connectivity = ConnectivityStub()
        suite = "ArticlesTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        manager = ArticleManager(provider: provider, cache: cache, connectivity: connectivity,
            bookmarks: BookmarkManager(defaults: defaults), logger: XCGLogger(identifier: "Tests", includeDefaultDestinations: false))
    }
    override func tearDown() async throws { defaults.removePersistentDomain(forName: suite) }

    func testNetworkResultPersists() async throws {
        let result = try await manager.refresh()
        XCTAssertEqual(result.origin, .network)
        let cached = try await cache.read()
        XCTAssertEqual(cached?.articles.first?.displayTitle, "New story")
        XCTAssertNil(result.warning)
    }
    func testOfflineUsesPersistedSnapshotWithoutNetworkRequest() async throws {
        await cache.seed(saved)
        connectivity.isOnline = false
        let result = try await manager.refresh()
        XCTAssertEqual(result.origin, .cache)
        XCTAssertEqual(result.snapshot, saved)
        XCTAssertEqual(provider.calls, 0)
        XCTAssertTrue(result.warning?.contains("offline") == true)
    }
    func testServerFailureUsesCacheWithoutReplacingIt() async throws {
        await cache.seed(saved)
        provider.result = .failure(ArticleError.invalidResponse)
        let result = try await manager.refresh()
        XCTAssertEqual(result.snapshot, saved)
        let persisted = try await cache.read()
        XCTAssertEqual(persisted, saved)
    }
    func testNoCacheAndOfflineThrows() async {
        connectivity.isOnline = false
        do { _ = try await manager.refresh(); XCTFail("Expected offline error") }
        catch { XCTAssertEqual(error.localizedDescription, ArticleError.offline.localizedDescription) }
    }
    func testNoCacheAndServerFailureThrows() async {
        provider.result = .failure(ArticleError.server(500))
        do { _ = try await manager.refresh(); XCTFail("Expected server error") }
        catch { XCTAssertEqual(provider.calls, 1) }
    }
    func testCacheWriteFailureStillDeliversFreshArticlesWithWarning() async throws {
        await cache.setFailWrite()
        let result = try await manager.refresh()
        XCTAssertEqual(result.origin, .network)
        XCTAssertEqual(result.snapshot.articles.first?.displayTitle, "New story")
        XCTAssertNotNil(result.warning)
    }
    func testCorruptCacheDoesNotPreventNetworkRecovery() async throws {
        await cache.setFailRead()
        let snapshot = await manager.cachedSnapshot()
        XCTAssertNil(snapshot)
        let result = try await manager.refresh()
        XCTAssertEqual(result.origin, .network)
    }
    func testSuccessfulEmptyResponseReplacesOldCache() async throws {
        await cache.seed(saved)
        provider.result = .success([])
        let result = try await manager.refresh()
        XCTAssertEqual(result.origin, .network)
        XCTAssertTrue(result.snapshot.articles.isEmpty)
        let cached = try await cache.read()
        XCTAssertEqual(cached?.articles, [])
    }
    func testOverlappingRefreshesShareOneRequest() async throws {
        provider.delay = 50_000_000
        async let first = manager.refresh()
        async let second = manager.refresh()
        let results = try await (first, second)
        XCTAssertEqual(provider.calls, 1)
        XCTAssertEqual(results.0.snapshot, results.1.snapshot)
    }
    func testConnectivityChangesForwardedToUI() {
        var changes: [Bool] = []
        manager.onConnectivityChange = { changes.append($0) }
        manager.startMonitoring()
        connectivity.change(false)
        connectivity.change(true)
        XCTAssertEqual(changes, [false, true])
    }
    func testBookmarkPersistsAcrossManagerInstances() {
        let article = Article(title: "Saved")
        XCTAssertFalse(manager.isBookmarked(article))
        XCTAssertTrue(manager.toggleBookmark(article))
        XCTAssertTrue(BookmarkManager(defaults: defaults).contains(article))
        XCTAssertFalse(manager.toggleBookmark(article))
        XCTAssertFalse(manager.isBookmarked(article))
    }
}
