import XCTest
import Alamofire
import XCGLogger
@testable import Articles

private final class StubURLProtocol: URLProtocol {
    static var status = 200
    static var data = Data()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class ArticleProviderTests: XCTestCase {
    private func provider(status: Int, body: String) -> ArticleProvider {
        StubURLProtocol.status = status
        StubURLProtocol.data = Data(body.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return ArticleProvider(session: Session(configuration: configuration), endpoint: URL(string: "https://example.com/articles")!,
            logger: XCGLogger(identifier: "ProviderTests", includeDefaultDestinations: false), decoder: ArticleResponseDecoder())
    }
    func testSuccessfulHTTPResponseDecodesArticles() async throws {
        let articles = try await provider(status: 200, body: #"{"articles":[{"title":"Network story"}]}"#).fetchArticles()
        XCTAssertEqual(articles.first?.displayTitle, "Network story")
    }
    func testHTTPFailureReturnsServerError() async {
        do {
            _ = try await provider(status: 503, body: "Service unavailable").fetchArticles()
            XCTFail("Expected an HTTP error")
        } catch ArticleError.server(let code) { XCTAssertEqual(code, 503) }
        catch { XCTFail("Unexpected error: \(error)") }
    }
    func testSuccessfulHTTPWithInvalidJSONReturnsParsingError() async {
        do {
            _ = try await provider(status: 200, body: "{broken").fetchArticles()
            XCTFail("Expected a parsing error")
        } catch ArticleError.invalidResponse { }
        catch { XCTFail("Unexpected error: \(error)") }
    }
}
