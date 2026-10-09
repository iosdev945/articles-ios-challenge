import UIKit
import Alamofire
import Swinject
import XCGLogger

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    let container = Container()
    private(set) var router: ArticleRouter!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MainActor.assumeIsolated { configureDependencies() }
        return true
    }
    @MainActor private func configureDependencies() {
        let logger = XCGLogger(identifier: "Articles", includeDefaultDestinations: false)
        logger.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: false, showLineNumbers: false)
        #if !DEBUG
        logger.outputLevel = .warning
        #endif
        container.register(XCGLogger.self) { _ in logger }.inObjectScope(.container)
        container.register(ArticleProviding.self) { resolver in
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 30
            return ArticleProvider(session: Session(configuration: configuration),
                endpoint: URL(string: "https://mocki.io/v1/9f09ed09-d8ca-48c7-9957-dec39e745321")!,
                logger: resolver.resolve(XCGLogger.self)!, decoder: ArticleResponseDecoder())
        }.inObjectScope(.container)
        var persistenceAvailable = true
        let cache: ArticleCaching
        do { cache = try ArticleCache() }
        catch {
            logger.error("Disk cache initialization failed: \(error.localizedDescription)")
            persistenceAvailable = false
            cache = MemoryArticleCache()
        }
        container.register(ArticleCaching.self) { _ in cache }.inObjectScope(.container)
        container.register(ConnectivityMonitoring.self) { resolver in
            MainActor.assumeIsolated { ConnectivityMonitor(logger: resolver.resolve(XCGLogger.self)!) }
        }.inObjectScope(.container)
        container.register(BookmarkManager.self) { _ in
            MainActor.assumeIsolated { BookmarkManager(defaults: .standard) }
        }.inObjectScope(.container)
        container.register(ArticleManaging.self) { resolver in
            MainActor.assumeIsolated {
                ArticleManager(provider: resolver.resolve(ArticleProviding.self)!, cache: resolver.resolve(ArticleCaching.self)!,
                    connectivity: resolver.resolve(ConnectivityMonitoring.self)!, bookmarks: resolver.resolve(BookmarkManager.self)!,
                    logger: resolver.resolve(XCGLogger.self)!, persistenceAvailable: persistenceAvailable)
            }
        }.inObjectScope(.container)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        container.register(ArticleListViewController.self) { resolver in
            MainActor.assumeIsolated {
                let controller = storyboard.instantiateViewController(withIdentifier: "ArticleList") as! ArticleListViewController
                controller.manager = resolver.resolve(ArticleManaging.self)!
                return controller
            }
        }
        container.register(ArticleDetailViewController.self) { resolver in
            MainActor.assumeIsolated {
                let controller = storyboard.instantiateViewController(withIdentifier: "ArticleDetail") as! ArticleDetailViewController
                controller.manager = resolver.resolve(ArticleManaging.self)!
                return controller
            }
        }
        router = ArticleRouter(makeList: { [container] in container.resolve(ArticleListViewController.self)! },
                               makeDetail: { [container] in container.resolve(ArticleDetailViewController.self)! })
    }
}
