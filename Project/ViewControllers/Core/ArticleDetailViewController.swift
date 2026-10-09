import UIKit

final class ArticleDetailViewController: UIViewController {
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var stateContainer: UIView!
    var manager: ArticleManaging!
    var article: Article?
    var onOpenURL: ((URL) -> Void)?
    var onShareURL: ((URL, UIBarButtonItem) -> Void)?
    private var state: StatePresenter!
    private lazy var bookmarkButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(bookmark))
    private lazy var shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(share))

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Design.ink
        title = "Article"
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Design.ink
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationItem.rightBarButtonItems = [shareButton, bookmarkButton]
        navigationItem.backButtonDisplayMode = .minimal
        shareButton.accessibilityLabel = "Share article"
        bookmarkButton.accessibilityIdentifier = "detail.bookmark"
        state = StatePresenter(parent: self, container: stateContainer)
        guard let article else {
            title = "Articles"
            scrollView.isHidden = true
            navigationItem.rightBarButtonItems = []
            state.show(.selection, message: "Choose a story from the list to start reading.")
            return
        }
        stateContainer.isHidden = true
        let header = ArticleHeaderView.instantiate()
        header.populate(article)
        contentStack.addArrangedSubview(header)
        let body = UILabel()
        body.numberOfLines = 0
        body.font = Design.font(16, style: .body)
        body.adjustsFontForContentSizeCategory = true
        body.textColor = .darkGray
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        body.attributedText = NSAttributedString(string: article.displayContent, attributes: [.paragraphStyle: paragraph])
        contentStack.addArrangedSubview(padded(body, color: Design.paper))
        let button = UIButton(type: .system)
        Design.actionButton(button)
        button.configuration?.title = article.articleURL == nil ? "Article link unavailable" : "Read full article"
        button.configuration?.image = UIImage(systemName: "safari")
        button.configuration?.imagePadding = 8
        button.isEnabled = article.articleURL != nil
        button.accessibilityIdentifier = "detail.openArticle"
        button.addTarget(self, action: #selector(openArticle), for: .touchUpInside)
        contentStack.addArrangedSubview(padded(button, color: Design.paper))
        shareButton.isEnabled = article.articleURL != nil
        updateBookmark()
    }
    private func padded(_ child: UIView, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = color
        child.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            child.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            child.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])
        return container
    }
    @objc private func bookmark() {
        guard let article else { return }
        let saved = manager.toggleBookmark(article)
        updateBookmark()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: saved ? "Article saved" : "Article removed from saved items")
    }
    private func updateBookmark() {
        guard let article else { return }
        let saved = manager.isBookmarked(article)
        bookmarkButton.image = UIImage(systemName: saved ? "heart.fill" : "heart")
        bookmarkButton.accessibilityLabel = saved ? "Remove bookmark" : "Bookmark article"
    }
    @objc private func openArticle() { if let url = article?.articleURL { onOpenURL?(url) } }
    @objc private func share() { if let url = article?.articleURL { onShareURL?(url, shareButton) } }
}
