import XCTest
@testable import Articles

final class ArticleDecoderTests: XCTestCase {
    private let decoder = ArticleResponseDecoder()
    private func decode(_ json: String) throws -> [Article] { try decoder.decode(Data(json.utf8)) }

    func testMissingFieldsHaveReadableFallbacks() throws {
        let article = try XCTUnwrap(decode(#"{"articles":[{"description":"A story","author":null,"urlToImage":null}]}"#).first)
        XCTAssertEqual(article.displayTitle, "Untitled article")
        XCTAssertEqual(article.displayAuthor, "Unknown author")
        XCTAssertEqual(article.displayContent, "A story")
        XCTAssertNil(article.imageURL)
        XCTAssertNil(article.articleURL)
    }
    func testWrongFieldTypesDoNotDiscardValidArticle() throws {
        let article = try XCTUnwrap(decode(#"{"articles":[{"title":42,"description":"Story","author":{},"source":[],"url":false}]}"#).first)
        XCTAssertEqual(article.displayTitle, "Untitled article")
        XCTAssertEqual(article.displayDescription, "Story")
        XCTAssertNil(article.articleURL)
    }
    func testMalformedEntriesAreSkippedAndDuplicatesRemoved() throws {
        let result = try decode(#"{"articles":[null,42,"bad",{}, {"title":"Good"},{"title":"Good"}]}"#)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.displayTitle, "Good")
    }
    func testInvalidJSONAndUnusableEnvelopeThrow() {
        for json in ["{", "null", "true", "{}", #"{"articles":null}"#, #"{"articles":{}}"#,
                     #"{"status":"error","articles":[]}"#, #"{"articles":[null,{}]}"#] {
            XCTAssertThrowsError(try decode(json), json)
        }
    }
    func testEmptyFeedIsSuccessfulAndBareArrayIsSupported() throws {
        XCTAssertEqual(try decode(#"{"articles":[]}"#), [])
        XCTAssertEqual(try decode(#"[{"title":"Good"}]"#).count, 1)
    }
    func testBlankStringsAndSourceAuthorFallback() throws {
        let article = try XCTUnwrap(decode(#"{"articles":[{"title":"  ","description":"Body","author":"","source":{"id":null,"name":" Publisher "},"urlToImage":" "}]}"#).first)
        XCTAssertEqual(article.displayAuthor, "Publisher")
        XCTAssertEqual(article.displayTitle, "Untitled article")
        XCTAssertNil(article.imageURL)
    }
    func testOnlyAbsoluteWebURLsAreAccepted() {
        for value in ["", " ", "not-a-link", "/article", "javascript:alert(1)", "file:///tmp/a", "https://", "https://example.com/with space", "https://user:password@example.com"] {
            XCTAssertNil(Article.webURL(value), value)
        }
        XCTAssertEqual(Article.webURL(" https://example.com/story ")?.host, "example.com")
        XCTAssertNotNil(Article.webURL("http://example.com/story"))
    }
    func testIdentityAndCodableRoundTripAreStable() throws {
        let article = Article(source: .init(name: "Publisher"), title: "Hello", url: "https://example.com", publishedAt: "2025-03-07T11:00:59Z")
        let restored = try JSONDecoder().decode(Article.self, from: JSONEncoder().encode(article))
        XCTAssertEqual(restored, article)
        XCTAssertEqual(restored.id, article.id)
        XCTAssertNotEqual(article.id, Article(title: "Different").id)
    }
    func testDatesHandleInvalidAndFractionalValues() {
        XCTAssertNil(Article(title: "Test", publishedAt: "invalid").publicationDate)
        XCTAssertNotNil(Article(title: "Test", publishedAt: "2025-03-07T11:00:59Z").publicationDate)
        XCTAssertNotNil(Article(title: "Test", publishedAt: "2025-03-07T11:00:59.123Z").publicationDate)
    }
    func testCapturedAPIEnvelopeDecodesAllUsableArticles() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "api-response", withExtension: "json"))
        let articles = try decoder.decode(Data(contentsOf: url))
        XCTAssertEqual(articles.count, 79)
        XCTAssertTrue(articles.contains { $0.title == nil })
        XCTAssertTrue(articles.contains { $0.imageURL == nil })
    }
}
