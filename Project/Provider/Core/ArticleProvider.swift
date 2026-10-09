import Foundation
import Alamofire
import XCGLogger

final class ArticleProvider: ArticleProviding {
    private let session: Session
    private let endpoint: URL
    private let logger: XCGLogger
    private let decoder: ArticleResponseDecoder

    init(session: Session, endpoint: URL, logger: XCGLogger, decoder: ArticleResponseDecoder) {
        self.session = session; self.endpoint = endpoint; self.logger = logger; self.decoder = decoder
    }
    func fetchArticles() async throws -> [Article] {
        logger.info("GET \(endpoint.absoluteString)")
        let request = session.request(endpoint).validate(statusCode: 200..<300)
        let response = await request.serializingData().response
        let status = response.response?.statusCode ?? 0
        logger.debug("Response status=\(status), bytes=\(response.data?.count ?? 0)")
        do {
            let data = try response.result.get()
            let articles = try decoder.decode(data)
            logger.info("Decoded \(articles.count) articles")
            return articles
        } catch {
            logger.error("Article request failed: \(error.localizedDescription)")
            if let error = error as? ArticleError { throw error }
            if status >= 400 { throw ArticleError.server(status) }
            throw ArticleError.transport(error)
        }
    }
}
