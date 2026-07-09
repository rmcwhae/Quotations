//
//  DeepLinkRouter.swift
//  Quotations
//

import Foundation
import Observation
import SwiftUI

extension Notification.Name {
    static let quotationDeepLinkReceived = Notification.Name("quotationDeepLinkReceived")
    /// Temporary: in-app debug alert for deep link diagnosis.
    static let quotationDeepLinkDebug = Notification.Name("quotationDeepLinkDebug")
}

/// Temporary debug surface for deep link diagnosis. Remove when widget linking is stable.
enum DeepLinkDebug {
    static func report(_ event: String, url: URL? = nil, details: [String: String] = [:]) {
        var lines = [event]
        if let url {
            lines.append("URL: \(url.absoluteString)")
        }
        for (key, value) in details.sorted(by: { $0.key < $1.key }) {
            lines.append("\(key): \(value)")
        }
        NotificationCenter.default.post(
            name: .quotationDeepLinkDebug,
            object: nil,
            userInfo: ["message": lines.joined(separator: "\n")]
        )
    }
}

struct DeepLinkDebugModifier: ViewModifier {
    @Binding var message: String
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .quotationDeepLinkDebug)) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    self.message = message
                    isPresented = true
                }
            }
            .alert("Deep Link Debug", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

/// Holds URLs delivered before SwiftUI is ready to receive them (cold launch from widget).
enum DeepLinkLaunchQueue {
    private static var pendingURLs: [URL] = []
    private static let lock = NSLock()

    static func enqueue(_ url: URL) {
        lock.lock()
        pendingURLs.append(url)
        lock.unlock()
        DeepLinkDebug.report("Launch queue enqueue", url: url)
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
        DeepLinkDebug.report("Router enqueue", url: url)
        NotificationCenter.default.post(name: .quotationDeepLinkReceived, object: nil)
    }

    func consumePendingURL() -> URL? {
        let url = pendingURL
        pendingURL = nil
        return url
    }
}
