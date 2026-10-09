import UIKit

/// Tokens sampled from the supplied design reference; Figma source measurement is still pending.
enum Design {
    static let ink = UIColor(red: 0.12, green: 0.23, blue: 0.27, alpha: 1)
    static let paper = UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1)
    static let accent = UIColor(red: 0.10, green: 0.39, blue: 0.58, alpha: 1)
    static let muted = UIColor(red: 0.66, green: 0.74, blue: 0.76, alpha: 1)
    static let spacing: CGFloat = 16
    static func font(_ size: CGFloat, weight: UIFont.Weight = .regular, style: UIFont.TextStyle = .body) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: size, weight: weight))
    }
    static func date(_ date: Date?) -> String {
        guard let date else { return "Date unavailable" }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
    static func actionButton(_ button: UIButton) {
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) { config = .prominentGlass() }
        else { config = .filled() }
        config.baseBackgroundColor = accent
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        button.configuration = config
    }
}
