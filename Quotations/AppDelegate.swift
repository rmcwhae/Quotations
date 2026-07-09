//
//  AppDelegate.swift
//  Quotations
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { url in
            DeepLinkLaunchQueue.enqueue(url)
        }
    }
}
