import Foundation

@MainActor
final class BookmarkManager {
    private let defaults: UserDefaults
    private let key = "bookmarkedArticleIDs"
    init(defaults: UserDefaults) { self.defaults = defaults }
    func contains(_ article: Article) -> Bool { Set(defaults.stringArray(forKey: key) ?? []).contains(article.id) }
    func toggle(_ article: Article) -> Bool {
        var ids = Set(defaults.stringArray(forKey: key) ?? [])
        if !ids.insert(article.id).inserted { ids.remove(article.id) }
        defaults.set(Array(ids).sorted(), forKey: key)
        return ids.contains(article.id)
    }
}
