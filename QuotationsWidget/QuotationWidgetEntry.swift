//
//  QuotationWidgetEntry.swift
//  QuotationsWidget
//

import Foundation
import WidgetKit

struct QuotationWidgetEntry: TimelineEntry {
    let date: Date
    let content: String?
    let authorName: String?
    let sourceTitle: String?
    let deepLinkURL: URL?
}

extension QuotationWidgetEntry {
    static let placeholder = QuotationWidgetEntry(
        date: .now,
        content: "The only way to do great work is to love what you do.",
        authorName: "Steve Jobs",
        sourceTitle: "Biography",
        deepLinkURL: QuotationDeepLink.url(for: .home)
    )

    static let empty = QuotationWidgetEntry(
        date: .now,
        content: nil,
        authorName: nil,
        sourceTitle: nil,
        deepLinkURL: QuotationDeepLink.url(for: .home)
    )
}
