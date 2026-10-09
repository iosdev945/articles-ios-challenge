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
    func testGridCellKeepsVisibleTitleAfterWidthChange() {
        let cell = Bundle(for: ArticleCell.self).loadNibNamed("ArticleCell", owner: nil)!.first as! ArticleCell
        let article = Article(title: "A readable grid title that wraps")
        cell.frame = CGRect(x: 0, y: 0, width: 300, height: ArticleCell.height(for: article, width: 300, compact: true))
        cell.populate(article, compact: true, width: 300, selected: false)
        cell.layoutIfNeeded()
        cell.frame.size = CGSize(width: 150, height: ArticleCell.height(for: article, width: 150, compact: true))
        cell.layoutIfNeeded()
        func labels(in view: UIView) -> [UILabel] { view.subviews.flatMap { ($0 as? UILabel).map { [$0] } ?? labels(in: $0) } }
        let title = labels(in: cell).first { $0.text == article.displayTitle }
        XCTAssertNotNil(title)
        XCTAssertGreaterThanOrEqual(title!.bounds.height, title!.font.lineHeight)
    }
    func testCellHeightExpandsForLongTitles() {
        let short = ArticleCell.height(for: Article(title: "Short"), width: 340, compact: false)
        let long = ArticleCell.height(for: Article(title: String(repeating: "A long article title ", count: 20)), width: 340, compact: false)
        XCTAssertGreaterThan(long, short)
    }
}
