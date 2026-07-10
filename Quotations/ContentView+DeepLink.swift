//
//  ContentView+DeepLink.swift
//  Quotations
//

import AppKit
import os
import SwiftData
import SwiftUI

extension ContentView {
    static let deepLinkLog = Logger(subsystem: "com.russellmcwhae.Quotations", category: "DeepLink")

    func handleDeepLink(_ url: URL, retryCount: Int = 0) {
        guard let parameters = QuotationDeepLink.parseURLParameters(url) else {
            Self.deepLinkLog.debug("Ignoring deep link without quotation id: \(url.absoluteString, privacy: .public)")
            return
        }

        guard let quotation = QuotationDeepLinkResolver.quotation(
            encodedID: parameters.encodedQuotationID,
            in: modelContext
        ) else {
            scheduleDeepLinkRetry(url, retryCount: retryCount)
            return
        }

        guard let resolvedSourceID = QuotationDeepLinkResolver.sourceID(
            encodedID: parameters.encodedSourceID,
            for: quotation,
            in: modelContext
        ) else {
            unresolvedDeepLinkURL = url
            Self.deepLinkLog.error(
                "Resolved quotation but not source for deep link. url=\(url.absoluteString, privacy: .public)"
            )
            return
        }

        openDeepLink(quotation: quotation, sourceId: resolvedSourceID, url: url)
    }

    private func scheduleDeepLinkRetry(_ url: URL, retryCount: Int) {
        guard retryCount < 10 else {
            Self.deepLinkLog.error(
                """
                Failed to resolve quotation deep link after retries. \
                url=\(url.absoluteString, privacy: .public) \
                sharedStoreExists=\(AppGroupStore.sharedStoreExists, privacy: .public)
                """
            )
            return
        }
        unresolvedDeepLinkURL = url
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            handleDeepLink(url, retryCount: retryCount + 1)
        }
    }

    private func openDeepLink(quotation: Quotation, sourceId: PersistentIdentifier, url: URL) {
        NSApp.activate(ignoringOtherApps: true)
        searchState.query = ""
        findInPage.query = ""
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            navigation.openQuotationFromDeepLink(
                quotation.persistentModelID,
                sourceId: sourceId
            )
        }
        isInspectorShown = false
        unresolvedDeepLinkURL = url

        Task { @MainActor in
            await Task.yield()
            verifyDeepLinkNavigation(for: url)
        }
    }

    func verifyDeepLinkNavigation(for url: URL) {
        guard unresolvedDeepLinkURL == url else { return }
        if let quotationId = navigation.selectedQuotationId,
           let sourceId = navigation.selectedSourceId,
           modelContext.model(for: quotationId) is Quotation,
           modelContext.model(for: sourceId) is Source {
            unresolvedDeepLinkURL = nil
            return
        }
        retryUnresolvedDeepLinkIfNeeded()
    }

    func consumePendingDeepLinkIfNeeded() {
        DeepLinkLaunchQueue.flush(into: deepLinkRouter)
        guard let url = deepLinkRouter.consumePendingURL() else { return }
        Task { @MainActor in
            await Task.yield()
            handleDeepLink(url)
        }
    }

    func retryUnresolvedDeepLinkIfNeeded() {
        guard let url = unresolvedDeepLinkURL else { return }
        handleDeepLink(url)
    }
}
