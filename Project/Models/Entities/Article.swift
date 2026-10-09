import Foundation
import CryptoKit

/// Keeps the wire representation Codable; presentation fallbacks never overwrite API data.
struct Article: Codable, Equatable, Identifiable {
    struct Source: Codable, Equatable {
        let id: String?
        let name: String?
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = values.string(.id)
            name = values.string(.name)
        }
        init(id: String? = nil, name: String? = nil) { self.id = id; self.name = name }
    }

    let source: Source?
    let author: String?
    let title: String?
    let description: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: String?
    let content: String?

    init(source: Source? = nil, author: String? = nil, title: String? = nil,
         description: String? = nil, url: String? = nil, urlToImage: String? = nil,
         publishedAt: String? = nil, content: String? = nil) {
        self.source = source; self.author = author; self.title = title
        self.description = description; self.url = url; self.urlToImage = urlToImage
        self.publishedAt = publishedAt; self.content = content
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        source = try? values.decodeIfPresent(Source.self, forKey: .source)
        author = values.string(.author)
        title = values.string(.title)
        description = values.string(.description)
        url = values.string(.url)
        urlToImage = values.string(.urlToImage)
        publishedAt = values.string(.publishedAt)
        content = values.string(.content)
    }

    // A repeatable identity across requests and app launches, independent of Swift's random hash seed.
    var id: String {
        let fields = [url, title, publishedAt, source?.name, content, description, author, urlToImage]
        let bytes = (try? JSONEncoder().encode(fields)) ?? Data()
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
    var displayTitle: String { title.cleaned ?? "Untitled article" }
    var displayDescription: String { description.cleaned ?? "No description available." }
    var displayAuthor: String { author.cleaned ?? source?.name.cleaned ?? "Unknown author" }
    var displayContent: String { content.cleaned ?? description.cleaned ?? "The publisher has not provided article text." }
    var articleURL: URL? { Self.webURL(url) }
    var imageURL: URL? { Self.webURL(urlToImage) }
    var publicationDate: Date? {
        guard let value = publishedAt.cleaned else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter.date(from: value)
    }
    static func webURL(_ value: String?) -> URL? {
        guard let string = value.cleaned, !string.contains(where: { $0.isWhitespace }),
              let components = URLComponents(string: string),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil else { return nil }
        return components.url
    }
}

extension Optional where Wrapped == String {
    var cleaned: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
private extension KeyedDecodingContainer {
    func string(_ key: Key) -> String? { try? decodeIfPresent(String.self, forKey: key) }
}
