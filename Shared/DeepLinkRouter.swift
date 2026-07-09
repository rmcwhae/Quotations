//
//  DeepLinkRouter.swift
//  Quotations
//

import Foundation
import Observation

extension Notification.Name {
    static let quotationDeepLinkReceived = Notification.Name("quotationDeepLinkReceived")
}

/// Holds URLs delivered before SwiftUI is ready to receive them (cold launch from widget).
enum DeepLinkLaunchQueue {
    private static var pendingURLs: [URL] = []
    private static let lock = NSLock()

    static func enqueue(_ url: URL) {
        lock.lock()
        pendingURLs.append(url)
        lock.unlock()
        NotificationCenter.default.post(name: .quotationDeepLinkReceived, object: nil)
    }

    static func flush(into router: DeepLinkRouter) {
        lock.lock()
        let urls = pendingURLs
        pendingURLs.removeAll()
        lock.unlock()
        urls.forEach { router.enqueue($0) }
    }
}

@Observable
final class DeepLinkRouter {
    private(set) var pendingURL: URL?

    func enqueue(_ url: URL) {
        pendingURL = url
        NotificationCenter.default.post(name: .quotationDeepLinkReceived, object: nil)
    }

    func consumePendingURL() -> URL? {
        let url = pendingURL
        pendingURL = nil
        return url
    }
}
