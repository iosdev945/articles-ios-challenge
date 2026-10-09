import UIKit

final class ArticleHeaderView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var metadataLabel: UILabel!
    @IBOutlet private weak var articleImage: ArticleImageView!

    static func instantiate() -> ArticleHeaderView {
        // This nib is bundled by the app target and verified by the resource-loading test.
        Bundle.main.loadNibNamed("ArticleHeaderView", owner: nil)?.first as! ArticleHeaderView
    }
    func populate(_ article: Article) {
        backgroundColor = Design.ink
        titleLabel.font = Design.font(23, weight: .bold, style: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .white
        titleLabel.text = article.displayTitle
        titleLabel.accessibilityTraits = .header
        metadataLabel.font = Design.font(12, style: .caption1)
        metadataLabel.adjustsFontForContentSizeCategory = true
        metadataLabel.textColor = Design.muted
        metadataLabel.text = "\(Design.date(article.publicationDate))\n\(article.displayAuthor)"
        articleImage.layer.cornerRadius = 6
        articleImage.load(article.imageURL)
    }
}
