import Foundation
import XCGLogger

@MainActor
protocol ArticleManaging: AnyObject {
    var isOnline: Bool { get }
    var onConnectivityChange: ((Bool) -> Void)? { get set }
    func startMonitoring()
    func cachedSnapshot() async -> ArticleSnapshot?
    func refresh() async throws -> ArticleLoadResult
    func isBookmarked(_ article: Article) -> Bool
    @discardableResult func toggleBookmark(_ article: Article) -> Bool
}

@MainActor
final class ArticleManager: ArticleManaging {
    private let provider: ArticleProviding
    private let cache: ArticleCaching
    private let connectivity: ConnectivityMonitoring
    private let bookmarks: BookmarkManager
    private let logger: XCGLogger
    private let persistenceAvailable: Bool
    private var inFlight: Task<ArticleLoadResult, Error>?
    var onConnectivityChange: ((Bool) -> Void)?
    var isOnline: Bool { connectivity.isOnline }

    init(provider: ArticleProviding, cache: ArticleCaching, connectivity: ConnectivityMonitoring,
         bookmarks: BookmarkManager, logger: XCGLogger, persistenceAvailable: Bool = true) {
        self.provider = provider; self.cache = cache; self.connectivity = connectivity
        self.bookmarks = bookmarks; self.logger = logger; self.persistenceAvailable = persistenceAvailable
    }
    func startMonitoring() {
        connectivity.onChange = { [weak self] online in self?.onConnectivityChange?(online) }
        connectivity.start()
    }
    func cachedSnapshot() async -> ArticleSnapshot? {
        do { return try await cache.read() }
        catch { logger.warning("Cannot read cache: \(error.localizedDescription)"); return nil }
    }
    func refresh() async throws -> ArticleLoadResult {
        if let inFlight { return try await inFlight.value }
        let task = Task { @MainActor [self] () throws -> ArticleLoadResult in
            do {
                guard isOnline else { throw ArticleError.offline }
                let articles = try await provider.fetchArticles()
                let snapshot = ArticleSnapshot(articles: articles, savedAt: Date())
                var warning: String? = persistenceAvailable ? nil : "Articles cannot be saved on this device."
                do { try await cache.write(snapshot) }
                catch {
                    logger.warning("Cache write failed: \(error.localizedDescription)")
                    warning = "Articles loaded, but could not be saved for offline use."
                }
                return ArticleLoadResult(snapshot: snapshot, origin: .network, warning: warning)
            } catch {
                if let saved = await cachedSnapshot() {
                    return ArticleLoadResult(snapshot: saved, origin: .cache,
                        warning: isOnline ? "Couldn’t refresh. Showing saved articles." : "You’re offline. Showing saved articles.")
                }
                throw error
            }
        }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
    func isBookmarked(_ article: Article) -> Bool { bookmarks.contains(article) }
    @discardableResult func toggleBookmark(_ article: Article) -> Bool { bookmarks.toggle(article) }
}
