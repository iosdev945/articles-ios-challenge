import UIKit
import SafariServices

@MainActor
final class ArticleRouter: NSObject, UISplitViewControllerDelegate, UINavigationControllerDelegate {
    private let makeList: () -> ArticleListViewController
    private let makeDetail: () -> ArticleDetailViewController
    private weak var split: UISplitViewController?
    private weak var listNavigation: UINavigationController?
    private weak var currentDetail: ArticleDetailViewController?
    private var selectedArticle: Article?

    init(makeList: @escaping () -> ArticleListViewController, makeDetail: @escaping () -> ArticleDetailViewController) {
        self.makeList = makeList; self.makeDetail = makeDetail
    }
    func rootViewController() -> UIViewController {
        let split = UISplitViewController(style: .doubleColumn)
        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredSplitBehavior = .tile
        split.minimumPrimaryColumnWidth = 320
        split.maximumPrimaryColumnWidth = 460
        split.preferredPrimaryColumnWidthFraction = 0.38
        split.delegate = self
        let list = makeList()
        list.onSelect = { [weak self] article in self?.open(article) }
        let navigation = ArticleNavigationController(rootViewController: list)
        configure(navigation, detail: false)
        navigation.delegate = self
        split.setViewController(navigation, for: .primary)
        let placeholder = detailController(nil)
        let detailNavigation = ArticleNavigationController(rootViewController: placeholder)
        configure(detailNavigation, detail: true)
        split.setViewController(detailNavigation, for: .secondary)
        self.split = split
        listNavigation = navigation
        currentDetail = placeholder
        return split
    }
    private func detailController(_ article: Article?) -> ArticleDetailViewController {
        let detail = makeDetail()
        detail.article = article
        detail.onOpenURL = { [weak detail] url in
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = Design.accent
            detail?.present(safari, animated: true)
        }
        detail.onShareURL = { [weak detail] url, sender in
            let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            sheet.popoverPresentationController?.barButtonItem = sender
            detail?.present(sheet, animated: true)
        }
        return detail
    }
    private func open(_ article: Article) {
        guard let split else { return }
        selectedArticle = article
        let detail = detailController(article)
        currentDetail = detail
        if split.isCollapsed {
            listNavigation?.popToRootViewController(animated: false)
            listNavigation?.pushViewController(detail, animated: true)
        } else {
            let navigation = ArticleNavigationController(rootViewController: detail)
            configure(navigation, detail: true)
            split.setViewController(navigation, for: .secondary)
            split.show(.secondary)
        }
    }
    private func configure(_ navigation: UINavigationController, detail: Bool) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = detail ? Design.ink : Design.paper
        appearance.titleTextAttributes = [.foregroundColor: detail ? UIColor.white : Design.ink,
                                           .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
        navigation.navigationBar.standardAppearance = appearance
        navigation.navigationBar.scrollEdgeAppearance = appearance
        navigation.navigationBar.compactAppearance = appearance
        navigation.navigationBar.tintColor = detail ? .white : Design.ink
    }
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        .primary
    }
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        guard let selectedArticle, !(listNavigation?.topViewController is ArticleDetailViewController) else { return }
        let detail = detailController(selectedArticle)
        currentDetail = detail
        listNavigation?.pushViewController(detail, animated: false)
    }
    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        listNavigation?.popToRootViewController(animated: false)
        guard let selectedArticle else { return }
        let detail = detailController(selectedArticle)
        currentDetail = detail
        let navigation = ArticleNavigationController(rootViewController: detail)
        configure(navigation, detail: true)
        svc.setViewController(navigation, for: .secondary)
    }
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let opensDetail = toVC is ArticleDetailViewController || (toVC as? UINavigationController)?.topViewController is ArticleDetailViewController
        guard operation == .push, opensDetail, !UIAccessibility.isReduceMotionEnabled else { return nil }
        return ArticleTransition()
    }
}
