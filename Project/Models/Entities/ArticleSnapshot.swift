import Foundation

struct ArticleSnapshot: Codable, Equatable {
    let articles: [Article]
    let savedAt: Date
}

struct ArticleLoadResult {
    enum Origin { case network, cache }
    let snapshot: ArticleSnapshot
    let origin: Origin
    let warning: String?
}
