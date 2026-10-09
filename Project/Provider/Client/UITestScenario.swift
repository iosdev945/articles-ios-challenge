#if DEBUG
import Foundation

/// Deterministic launch scenarios for UI regression tests. Never used in Release builds.
struct UITestScenario {
    let name: String
    static var current: UITestScenario? {
        guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--ui-scenario=") }) else { return nil }
        return UITestScenario(name: String(argument.dropFirst("--ui-scenario=".count)))
    }
    var provider: ArticleProviding { ScenarioProvider(name: name) }
    @MainActor var connectivity: ConnectivityMonitoring { ScenarioConnectivity(online: !name.hasPrefix("offline")) }
    var saved: ArticleSnapshot? {
        name == "offline-cached" ? ArticleSnapshot(articles: Self.articles, savedAt: Date(timeIntervalSince1970: 1741345259)) : nil
    }
    static var articles: [Article] {
        [
            Article(author: "Editorial desk", title: "How did China Become The World’s Factory?",
                    description: "An inside look at the people and places behind a changing world.",
                    url: "https://example.com/article", publishedAt: "2025-03-07T11:00:59Z",
                    content: "A closer look at the stories shaping our world.\n\nThe mock API provides article summaries and content. This deterministic story is only used by automated UI tests.\n\nOpen the full article to continue reading in Safari."),
            Article(title: nil, description: "A story with no title, author, date, image or usable link.", url: "invalid"),
            Article(author: "", title: "Thoughtful layouts work at every text size and on every screen", description: nil,
                    url: "https://example.com/layout", publishedAt: "invalid"),
            Article(source: .init(name: "Publisher"), title: "Peace, dignity and equality on a healthy planet", description: "A healthier future.", url: "https://example.com/planet", publishedAt: "2025-03-07T11:00:59Z")
        ]
    }
}
private struct ScenarioProvider: ArticleProviding {
    let name: String
    func fetchArticles() async throws -> [Article] {
        if name == "empty" { return [] }
        if name == "error" { throw ArticleError.invalidResponse }
        return UITestScenario.articles
    }
}
@MainActor private final class ScenarioConnectivity: ConnectivityMonitoring {
    let isOnline: Bool
    var onChange: ((Bool) -> Void)?
    init(online: Bool) { isOnline = online }
    func start() {}
}
#endif
