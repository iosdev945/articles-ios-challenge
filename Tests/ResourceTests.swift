import XCTest
@testable import Articles

@MainActor final class ResourceTests: XCTestCase {
    func testStoryboardScenesAndNibClassesAreBundled() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ArticleListViewController.self))
        XCTAssertTrue(storyboard.instantiateViewController(withIdentifier: "ArticleList") is ArticleListViewController)
        XCTAssertTrue(storyboard.instantiateViewController(withIdentifier: "ArticleDetail") is ArticleDetailViewController)
        XCTAssertNotNil(ArticleHeaderView.instantiate())
        let objects = Bundle(for: ArticleCell.self).loadNibNamed("ArticleCell", owner: nil)
        XCTAssertTrue(objects?.first is ArticleCell)
    }
    func testCellHeightExpandsForLongTitles() {
        let short = ArticleCell.height(for: Article(title: "Short"), width: 340, compact: false)
        let long = ArticleCell.height(for: Article(title: String(repeating: "A long article title ", count: 20)), width: 340, compact: false)
        XCTAssertGreaterThan(long, short)
    }
}
