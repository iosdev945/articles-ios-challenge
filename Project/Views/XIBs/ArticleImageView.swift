import UIKit
import Kingfisher

/// Shared by list cards and detail headers. Reuse always cancels the previous image request.
final class ArticleImageView: UIImageView {
    private let fallback = UIImageView(image: UIImage(systemName: "square.stack.3d.up"))
    override init(frame: CGRect) { super.init(frame: frame); configure() }
    required init?(coder: NSCoder) { super.init(coder: coder); configure() }
    private func configure() {
        backgroundColor = Design.paper
        contentMode = .scaleAspectFill
        clipsToBounds = true
        isAccessibilityElement = false
        fallback.translatesAutoresizingMaskIntoConstraints = false
        fallback.tintColor = .systemGray3
        fallback.contentMode = .scaleAspectFit
        addSubview(fallback)
        NSLayoutConstraint.activate([
            fallback.centerXAnchor.constraint(equalTo: centerXAnchor),
            fallback.centerYAnchor.constraint(equalTo: centerYAnchor),
            fallback.widthAnchor.constraint(equalToConstant: 68),
            fallback.heightAnchor.constraint(equalToConstant: 68)
        ])
    }
    func load(_ url: URL?) {
        reset()
        guard let url else { return }
        kf.setImage(with: url, options: [.transition(.fade(0.2)), .cacheOriginalImage, .retryStrategy(DelayRetryStrategy(maxRetryCount: 1, retryInterval: .seconds(1)))]) { [weak self] result in
            guard case .success = result else { return }
            self?.fallback.isHidden = true
        }
    }
    func reset() {
        kf.cancelDownloadTask()
        image = nil
        fallback.isHidden = false
    }
}
