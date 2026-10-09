import Foundation

/// Invalid root JSON is an error; invalid individual entries cannot poison otherwise usable data.
struct ArticleResponseDecoder {
    func decode(_ data: Data) throws -> [Article] {
        do {
            let root = try JSONSerialization.jsonObject(with: data)
            let entries: [Any]
            if let object = root as? [String: Any] {
                guard object["status"] as? String != "error", let array = object["articles"] as? [Any] else {
                    throw ArticleError.invalidResponse
                }
                entries = array
            } else if let array = root as? [Any] { entries = array }
            else { throw ArticleError.invalidResponse }
            var seen = Set<String>()
            let decoder = JSONDecoder()
            let articles = entries.compactMap { item -> Article? in
                guard let object = item as? [String: Any], !object.isEmpty,
                      let bytes = try? JSONSerialization.data(withJSONObject: object),
                      let article = try? decoder.decode(Article.self, from: bytes),
                      [article.title, article.description, article.url, article.content].contains(where: { $0.cleaned != nil }),
                      seen.insert(article.id).inserted else { return nil }
                return article
            }
            // An intentionally empty feed is valid; an entirely corrupt feed must not erase the cache.
            if !entries.isEmpty && articles.isEmpty { throw ArticleError.invalidResponse }
            return articles
        } catch { throw ArticleError.invalidResponse }
    }
}
