import UIKit

final class ArticleCell: UICollectionViewCell {
    static let reuseIdentifier = "ArticleCell"
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var articleImage: ArticleImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var readLabel: UILabel!
    @IBOutlet private weak var footerStack: UIStackView!
    @IBOutlet private weak var imageHeight: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.backgroundColor = Design.ink
        cardView.layer.cornerRadius = 8
        articleImage.layer.cornerRadius = 5
        titleLabel.textColor = .white
        dateLabel.textColor = Design.muted
        readLabel.textColor = .white
        readLabel.backgroundColor = Design.accent
        readLabel.layer.cornerRadius = 4
        readLabel.clipsToBounds = true
        titleLabel.adjustsFontForContentSizeCategory = true
        dateLabel.adjustsFontForContentSizeCategory = true
        readLabel.adjustsFontForContentSizeCategory = true
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    func populate(_ article: Article, compact: Bool, width: CGFloat, selected: Bool) {
        titleLabel.font = Design.font(compact ? 12 : 15, weight: .semibold, style: .headline)
        titleLabel.text = article.displayTitle
        dateLabel.font = Design.font(10, style: .caption2)
        dateLabel.text = "▢  \(Design.date(article.publicationDate))"
        readLabel.font = Design.font(11, weight: .semibold, style: .caption1)
        readLabel.text = "  Read More  ›  "
        footerStack.isHidden = compact
        imageHeight.constant = (width - 24) * 0.56
        articleImage.load(article.imageURL)
        cardView.layer.borderWidth = selected ? 2 : 0
        cardView.layer.borderColor = Design.accent.cgColor
        accessibilityLabel = "\(article.displayTitle), \(Design.date(article.publicationDate))"
        accessibilityHint = "Opens article details"
        accessibilityIdentifier = "article.card.\(article.id)"
    }
    static func height(for article: Article, width: CGFloat, compact: Bool) -> CGFloat {
        let font = Design.font(compact ? 12 : 15, weight: .semibold, style: .headline)
        let bounds = (article.displayTitle as NSString).boundingRect(
            with: CGSize(width: width - 24, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        let footer = compact ? CGFloat(8) : max(44, Design.font(11, style: .caption1).lineHeight + 20) + 8
        return ceil((width - 24) * 0.56 + bounds.height + 32 + footer)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        articleImage.reset()
        titleLabel.text = nil
        transform = .identity
    }
    override var isHighlighted: Bool {
        didSet {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            UIView.animate(withDuration: 0.12) { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity }
        }
    }
}
