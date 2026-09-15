import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
final class ShareViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let previewLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var openURL: URL?
    private var didHandle = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 320, height: 260)
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didHandle else { return }
        didHandle = true
        Task { await prepareShare() }
    }

    private func setupUI() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "正在读取分享内容…"
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = .preferredFont(forTextStyle: .footnote)
        previewLabel.textColor = .label
        previewLabel.numberOfLines = 3
        previewLabel.textAlignment = .center
        previewLabel.isHidden = true

        var openConfig = UIButton.Configuration.filled()
        openConfig.title = "打开 TakeIt"
        openConfig.cornerStyle = .large
        openConfig.baseBackgroundColor = .label
        openConfig.baseForegroundColor = .systemBackground
        openButton.configuration = openConfig
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.isHidden = true
        openButton.addTarget(self, action: #selector(openTapped), for: .touchUpInside)

        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "取消"
        cancelButton.configuration = cancelConfig
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            spinner, statusLabel, previewLabel, openButton, cancelButton,
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            openButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            openButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func prepareShare() async {
        guard let payload = await loadSharedPayload(),
              let url = IncomingURLParser.takeItOpenURL(for: payload)
        else {
            statusLabel.text = "没有找到可解析的链接"
            spinner.stopAnimating()
            spinner.isHidden = true
            return
        }

        openURL = url
        spinner.stopAnimating()
        spinner.isHidden = true
        statusLabel.text = "将用这条链接开始解析"
        previewLabel.text = payload
        previewLabel.isHidden = false
        openButton.isHidden = false
    }

    @objc private func openTapped() {
        guard let openURL else { return }
        openButton.isEnabled = false
        statusLabel.text = "正在打开 TakeIt…"
        openHost(openURL) { [weak self] success in
            guard let self else { return }
            if success {
                self.finish()
                return
            }
            self.openButton.isEnabled = true
            self.statusLabel.text = "无法自动跳转，请再试一次，或手动打开 TakeIt"
        }
    }

    @objc private func cancelTapped() {
        finish()
    }

    private func openHost(_ url: URL, completion: @escaping (Bool) -> Void) {
        if let scene = view.window?.windowScene {
            scene.open(url, options: nil) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                        return
                    }
                    self?.openWithSharedApplication(url, completion: completion)
                }
            }
            return
        }
        openWithSharedApplication(url, completion: completion)
    }

    private func openWithSharedApplication(_ url: URL, completion: @escaping (Bool) -> Void) {
        if let app = Self.sharedApplication() {
            app.open(url, options: [:]) { success in
                DispatchQueue.main.async { completion(success) }
            }
            return
        }
        completion(openWithResponder(url))
    }

    private func openWithResponder(_ url: URL) -> Bool {
        let selector = NSSelectorFromString("openURL:options:completionHandler:")
        var responder: UIResponder? = self
        while let current = responder {
            if current !== self, current.responds(to: selector), let imp = current.method(for: selector) {
                typealias OpenFn = @convention(c) (AnyObject, Selector, URL, NSDictionary, ((Bool) -> Void)?) -> Void
                unsafeBitCast(imp, to: OpenFn.self)(current, selector, url, [:], nil)
                return true
            }
            responder = current.next
        }
        return false
    }

    private static func sharedApplication() -> UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: selector) else { return nil }
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func loadSharedPayload() async -> String? {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        for item in items {
            if let text = item.attributedContentText?.string,
               let payload = IncomingURLParser.sharePayload(fromText: text) {
                return payload
            }
            if let payload = payload(fromUserInfo: item.userInfo) {
                return payload
            }
            for provider in item.attachments ?? [] {
                if let payload = await payload(from: provider) {
                    return payload
                }
            }
        }
        return nil
    }

    private func payload(fromUserInfo userInfo: [AnyHashable: Any]?) -> String? {
        guard let userInfo else { return nil }
        for value in userInfo.values {
            if let url = value as? URL,
               let payload = IncomingURLParser.shareURL(from: url) ?? IncomingURLParser.sharePayload(fromText: url.absoluteString) {
                return payload
            }
            if let text = value as? String, let payload = IncomingURLParser.sharePayload(fromText: text) {
                return payload
            }
            if let dict = value as? [String: Any] {
                for nested in dict.values {
                    if let text = nested as? String, let payload = IncomingURLParser.sharePayload(fromText: text) {
                        return payload
                    }
                }
            }
        }
        return nil
    }

    private func payload(from provider: NSItemProvider) async -> String? {
        let typeIDs = provider.registeredTypeIdentifiers
        let preferred = [
            UTType.url.identifier,
            UTType.plainText.identifier,
            UTType.utf8PlainText.identifier,
        ] + typeIDs.filter { id in
            let lower = id.lowercased()
            return lower.contains("url") || lower.contains("text") || lower.contains("plain")
        }

        var seen = Set<String>()
        for typeID in preferred where seen.insert(typeID).inserted {
            if let payload = await loadValue(from: provider, typeIdentifier: typeID) {
                return payload
            }
        }
        return nil
    }

    private func loadValue(from provider: NSItemProvider, typeIdentifier: String) async -> String? {
        guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                continuation.resume(returning: Self.payload(fromLoadedItem: item))
            }
        }
    }

    nonisolated private static func payload(fromLoadedItem item: NSSecureCoding?) -> String? {
        if let url = item as? URL {
            return payload(fromURL: url)
        }
        if let url = item as? NSURL {
            return payload(fromURL: url as URL)
        }
        if let text = item as? String {
            return IncomingURLParser.sharePayload(fromText: text)
        }
        if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
            return IncomingURLParser.sharePayload(fromText: text)
        }
        if let dict = item as? [String: Any] {
            for value in dict.values {
                if let text = value as? String, let payload = IncomingURLParser.sharePayload(fromText: text) {
                    return payload
                }
                if let url = value as? URL, let payload = IncomingURLParser.sharePayload(fromText: url.absoluteString) {
                    return payload
                }
            }
        }
        return nil
    }

    nonisolated private static func payload(fromURL url: URL) -> String? {
        if url.isFileURL {
            return IncomingURLParser.sharePayload(fromText: url.absoluteString)
        }
        return IncomingURLParser.shareURL(from: url) ?? IncomingURLParser.sharePayload(fromText: url.absoluteString)
    }
}
