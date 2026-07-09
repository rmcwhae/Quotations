//
//  QuotationTimelineProvider.swift
//  QuotationsWidget
//

import WidgetKit

struct QuotationTimelineProvider: TimelineProvider {
    /// How often the widget advances to the next quotation.
    private static let rotationInterval: TimeInterval = 30 * 60
    /// Number of timeline entries to schedule (~24 hours at the rotation interval).
    private static let entryCount = 48

    func placeholder(in context: Context) -> QuotationWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (QuotationWidgetEntry) -> Void) {
        completion(currentEntry() ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotationWidgetEntry>) -> Void) {
        let quotations = QuotationWidgetDataStore.fetchEligibleQuotations()
        let now = Date()

        guard !quotations.isEmpty else {
            let entry = QuotationWidgetEntry.empty
            let timeline = Timeline(entries: [entry], policy: .after(now.addingTimeInterval(Self.rotationInterval)))
            completion(timeline)
            return
        }

        var generator = SeededRandomNumberGenerator(
            seed: WidgetRefreshStore.refreshSeed ^ UInt64(quotations.count)
        )
        let shuffled = quotations.shuffled(using: &generator)
        var entries: [QuotationWidgetEntry] = []

        for index in 0..<Self.entryCount {
            let quote = shuffled[index % shuffled.count]
            entries.append(
                QuotationWidgetEntry(
                    date: now.addingTimeInterval(Double(index) * Self.rotationInterval),
                    content: quote.content,
                    authorName: quote.authorName,
                    sourceTitle: quote.sourceTitle,
                    deepLinkURL: Self.deepLinkURL(for: quote)
                )
            )
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentEntry() -> QuotationWidgetEntry? {
        let quotations = QuotationWidgetDataStore.fetchEligibleQuotations()
        var generator = SeededRandomNumberGenerator(
            seed: WidgetRefreshStore.refreshSeed ^ UInt64(quotations.count) ^ UInt64(Date().timeIntervalSince1970)
        )
        guard let quote = quotations.shuffled(using: &generator).first else { return nil }
        return QuotationWidgetEntry(
            date: .now,
            content: quote.content,
            authorName: quote.authorName,
            sourceTitle: quote.sourceTitle,
            deepLinkURL: Self.deepLinkURL(for: quote)
        )
    }

    private static func deepLinkURL(for quote: WidgetQuotationSnapshot) -> URL? {
        guard let url = QuotationDeepLink.url(
            for: .quotation(quote.quotationID, sourceID: quote.sourceID)
        ), QuotationDeepLink.isQuotationDeepLink(url) else {
            return nil
        }
        return url
    }
}
