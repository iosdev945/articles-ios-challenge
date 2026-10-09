import SwiftUI

struct ArticleStateView: View {
    enum Kind { case loading, offline, error, empty, search, selection }
    let kind: Kind
    let message: String
    var retry: (() -> Void)?
    private var icon: String {
        switch kind {
        case .loading: return "newspaper"
        case .offline: return "wifi.slash"
        case .error: return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .empty: return "newspaper"
        case .search: return "magnifyingglass"
        case .selection: return "doc.text.magnifyingglass"
        }
    }
    private var title: String {
        switch kind {
        case .loading: return "Loading articles"
        case .offline: return "You’re offline"
        case .error: return "Unable to load articles"
        case .empty: return "No articles yet"
        case .search: return "No matching articles"
        case .selection: return "Select an article"
        }
    }
    var body: some View {
        VStack(spacing: 18) {
            if kind == .loading { ProgressView().tint(Color(uiColor: Design.ink)).scaleEffect(1.3) }
            else { Image(systemName: icon).font(.system(size: 52, weight: .ultraLight)).accessibilityHidden(true) }
            Text(title).font(.headline).multilineTextAlignment(.center)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let retry {
                Button(action: retry) { Label("Retry", systemImage: "arrow.clockwise").padding(.horizontal, 8) }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(uiColor: Design.accent))
                    .accessibilityIdentifier("state.retry")
            }
        }
        .foregroundStyle(Color(uiColor: Design.ink))
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: Design.paper))
    }
}
