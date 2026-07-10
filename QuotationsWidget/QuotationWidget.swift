//
//  QuotationWidget.swift
//  QuotationsWidget
//

import SwiftUI
import WidgetKit

struct QuotationWidget: Widget {
    let kind = "QuotationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotationTimelineProvider()) { entry in
            QuotationWidgetView(entry: entry)
        }
        .configurationDisplayName("Quotations")
        .description("Rotates through quotations from your library.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
