import Foundation

enum ArticleError: LocalizedError {
    case offline, invalidResponse, server(Int), transport(Error), cacheUnavailable
    var errorDescription: String? {
        switch self {
        case .offline: return "Please connect to the internet and try again."
        case .invalidResponse: return "The server returned unreadable articles. Please try again."
        case .server: return "The server is temporarily unavailable. Please try again."
        case .transport: return "Articles could not be loaded. Please try again."
        case .cacheUnavailable: return "Saved articles could not be read. Please reconnect to load them."
        }
    }
}
