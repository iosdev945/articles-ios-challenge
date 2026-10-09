import Foundation

protocol ArticleProviding {
    func fetchArticles() async throws -> [Article]
}
