import UIKit

final class ArticleNavigationController: UINavigationController {
    override var childForStatusBarStyle: UIViewController? { topViewController }
}
