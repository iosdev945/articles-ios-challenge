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
    init(name: String = "Articles-v1", directory: URL? = nil) throws {
        let cacheDirectory = try directory ?? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        var excludedDirectory = cacheDirectory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try excludedDirectory.setResourceValues(values)
        storage = try Storage<String, ArticleSnapshot>(
            diskConfig: DiskConfig(name: name, expiry: .never, maxSize: 20 * 1024 * 1024, directory: cacheDirectory),
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
    init(snapshot: ArticleSnapshot? = nil) { self.snapshot = snapshot }
    func read() async throws -> ArticleSnapshot? { snapshot }
    func write(_ snapshot: ArticleSnapshot) async throws { self.snapshot = snapshot }
}
