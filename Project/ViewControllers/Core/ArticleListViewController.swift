import UIKit

final class ArticleListViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var stateContainer: UIView!
    @IBOutlet private weak var bannerLabel: UILabel!
    @IBOutlet private weak var bannerHeight: NSLayoutConstraint!
    var manager: ArticleManaging!
    var onSelect: ((Article) -> Void)?

    private var articles: [Article] = []
    private var visibleArticles: [Article] = []
    private var selectedID: String?
    private var grid = false
    private var query = ""
    private var refreshing = false
    private var lastWidth: CGFloat = 0
    private var state: StatePresenter!
    private var loadTask: Task<Void, Never>?
    private let search = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()
    private lazy var layoutButton = UIBarButtonItem(image: UIImage(systemName: "square.grid.2x2.fill"), style: .plain, target: self, action: #selector(toggleLayout))

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Articles"
        let titleLabel = UILabel()
        titleLabel.text = "Articles"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = Design.ink
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.title = ""
        navigationItem.backButtonTitle = "Articles"
        view.backgroundColor = Design.paper
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(openSearch)), layoutButton
        ]
        layoutButton.accessibilityLabel = "Show grid"
        layoutButton.accessibilityIdentifier = "list.layout"
        navigationItem.rightBarButtonItems?.first?.accessibilityLabel = "Search articles"
        collectionView.backgroundColor = Design.paper
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: ArticleCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: ArticleCell.reuseIdentifier)
        collectionView.refreshControl = refreshControl
        refreshControl.tintColor = Design.ink
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        state = StatePresenter(parent: self, container: stateContainer)
        bannerLabel.font = Design.font(12, weight: .medium, style: .caption1)
        bannerLabel.adjustsFontForContentSizeCategory = true
        bannerLabel.backgroundColor = Design.ink
        bannerLabel.textColor = .white
        bannerLabel.numberOfLines = 0
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search articles"
        search.delegate = self
        definesPresentationContext = true
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: ArticleListViewController, _) in
            controller.collectionView.reloadData()
            controller.collectionView.collectionViewLayout.invalidateLayout()
        }
        manager.onConnectivityChange = { [weak self] online in
            guard let self else { return }
            if online { self.beginRefresh() }
            else {
                self.showBanner(self.articles.isEmpty ? nil : "You’re offline. Showing saved articles.")
                if self.articles.isEmpty && !self.refreshing {
                    self.showState(.offline, message: "Please connect to the internet and try again.")
                }
            }
        }
        manager.startMonitoring()
        stateContainer.isHidden = false
        state.show(.loading, message: "Finding your next read…")
        loadTask = Task { [weak self] in
            guard let self else { return }
            if let saved = await manager.cachedSnapshot(), !saved.articles.isEmpty {
                articles = saved.articles
                applyFilter()
                showBanner("Showing saved articles · \(Design.date(saved.savedAt))")
            }
            await load()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = Design.ink
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if lastWidth != collectionView.bounds.width {
            lastWidth = collectionView.bounds.width
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    @objc private func refresh() { beginRefresh() }
    private func beginRefresh() {
        guard !refreshing else { return }
        loadTask = Task { [weak self] in await self?.load() }
    }
    private func load() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false; refreshControl.endRefreshing() }
        do {
            let result = try await manager.refresh()
            guard !Task.isCancelled else { return }
            articles = result.snapshot.articles
            showBanner(result.warning.map { "\($0)\(result.origin == .cache ? " Saved \(Design.date(result.snapshot.savedAt))." : "")" })
            applyFilter()
        } catch {
            guard !Task.isCancelled else { return }
            if articles.isEmpty {
                showState(manager.isOnline ? .error : .offline, message: error.localizedDescription)
            } else { showBanner("Couldn’t refresh. Showing saved articles.") }
        }
    }
    private func showBanner(_ message: String?) {
        bannerLabel.text = message.map { "  \($0)  " }
        bannerLabel.isHidden = message == nil
        let measured = bannerLabel.sizeThatFits(CGSize(width: max(200, view.bounds.width - 32), height: .greatestFiniteMagnitude)).height
        bannerHeight.constant = message == nil ? 0 : max(40, measured + 16)
    }
    private func showState(_ kind: ArticleStateView.Kind, message: String) {
        stateContainer.isHidden = false
        state.show(kind, message: message, retry: kind == .search || kind == .selection ? nil : { [weak self] in
            self?.state.show(.loading, message: "Finding your next read…")
            self?.beginRefresh()
        })
    }
    private func applyFilter() {
        visibleArticles = query.isEmpty ? articles : articles.filter {
            [$0.displayTitle, $0.displayDescription, $0.displayAuthor].contains { $0.localizedCaseInsensitiveContains(query) }
        }
        collectionView.reloadData()
        if visibleArticles.isEmpty {
            if !query.isEmpty { showState(.search, message: "Try a different title, author or keyword.") }
            else if !manager.isOnline { showState(.offline, message: "There are no saved articles. Connect to load the latest feed.") }
            else { showState(.empty, message: "Pull to refresh or try again shortly.") }
        } else { state.hide(); stateContainer.isHidden = true }
    }
    @objc private func toggleLayout() {
        grid.toggle()
        layoutButton.image = UIImage(systemName: grid ? "list.bullet" : "square.grid.2x2.fill")
        layoutButton.accessibilityLabel = grid ? "Show list" : "Show grid"
        UISelectionFeedbackGenerator().selectionChanged()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    @objc private func openSearch() {
        navigationItem.searchController = search
        search.isActive = true
        DispatchQueue.main.async { self.search.searchBar.becomeFirstResponder() }
    }
    private var columnCount: Int {
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory { return 1 }
        return grid ? max(2, Int(collectionView.bounds.width / 180)) : max(1, Int(collectionView.bounds.width / 540))
    }
}

extension ArticleListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { visibleArticles.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleCell.reuseIdentifier, for: indexPath) as! ArticleCell
        let article = visibleArticles[indexPath.item]
        let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
        cell.populate(article, compact: columnCount > 1, width: size.width, selected: article.id == selectedID && splitViewController?.isCollapsed == false)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns = columnCount
        let count = CGFloat(columns)
        let width = floor((collectionView.bounds.width - 32 - (count - 1) * 12) / count)
        let rowStart = (indexPath.item / columns) * columns
        let rowEnd = min(rowStart + columns, visibleArticles.count)
        let height = visibleArticles[rowStart..<rowEnd].map {
            ArticleCell.height(for: $0, width: width, compact: columns > 1)
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets { UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16) }
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat { 12 }
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 12 }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let article = visibleArticles[indexPath.item]
        selectedID = article.id
        collectionView.reloadData()
        onSelect?(article)
    }
}
extension ArticleListViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        applyFilter()
    }
    func didDismissSearchController(_ searchController: UISearchController) {
        query = ""
        navigationItem.searchController = nil
        applyFilter()
    }
}
