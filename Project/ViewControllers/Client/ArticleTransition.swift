import UIKit

/// A restrained crossfade and slide; system back gestures retain the default pop animation.
final class ArticleTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.28 }
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let destination = context.viewController(forKey: .to), let view = context.view(forKey: .to) else {
            context.completeTransition(false); return
        }
        view.frame = context.finalFrame(for: destination)
        context.containerView.addSubview(view)
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 28, y: 0)
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0, options: .curveEaseOut) {
            view.alpha = 1
            view.transform = .identity
        } completion: { _ in context.completeTransition(!context.transitionWasCancelled) }
    }
}
