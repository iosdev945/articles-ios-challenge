import UIKit
import SwiftUI

@MainActor
final class StatePresenter {
    private weak var parent: UIViewController?
    private let host: UIHostingController<ArticleStateView>
    init(parent: UIViewController, container: UIView) {
        self.parent = parent
        host = UIHostingController(rootView: ArticleStateView(kind: .loading, message: ""))
        parent.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        host.didMove(toParent: parent)
        hide()
    }
    func show(_ kind: ArticleStateView.Kind, message: String, retry: (() -> Void)? = nil) {
        host.rootView = ArticleStateView(kind: kind, message: message, retry: retry)
        host.view.isHidden = false
    }
    func hide() { host.view.isHidden = true }
}
