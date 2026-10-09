import Foundation
import Cache

protocol ArticleCaching {
    func read() async throws -> ArticleSnapshot?
    func write(_ snapshot: ArticleSnapshot) async throws
}

/// All Cache disk/memory operations are serialized off the UI thread.
actor ArticleCache: ArticleCaching {
    private let storage: Storage<String, ArticleSnapshot>
    private let key = "articles-v1"
    init() throws {
        storage = try Storage<String, ArticleSnapshot>(
            diskConfig: DiskConfig(name: "Articles-v1", expiry: .never, maxSize: 20 * 1024 * 1024),
            memoryConfig: MemoryConfig(expiry: .never, countLimit: 1, totalCostLimit: 0),
            transformer: TransformerFactory.forCodable(ofType: ArticleSnapshot.self)
        )
    }
    func read() async throws -> ArticleSnapshot? {
        if try !storage.existsObject(forKey: key) { return nil }
        return try storage.object(forKey: key)
    }
    func write(_ snapshot: ArticleSnapshot) async throws {
        try storage.setObject(snapshot, forKey: key)
    }
}

/// Only used if the disk cache cannot be initialized. The UI reports the loss of persistence.
actor MemoryArticleCache: ArticleCaching {
    private var snapshot: ArticleSnapshot?
    func read() async throws -> ArticleSnapshot? { snapshot }
    func write(_ snapshot: ArticleSnapshot) async throws { self.snapshot = snapshot }
}
