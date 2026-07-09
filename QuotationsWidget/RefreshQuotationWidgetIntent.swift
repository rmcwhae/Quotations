//
//  RefreshQuotationWidgetIntent.swift
//  QuotationsWidget
//

import AppIntents
import WidgetKit

struct RefreshQuotationWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh"
    static var description = IntentDescription("Shows a different quotation in the widget.")

    func perform() async throws -> some IntentResult {
        WidgetRefreshStore.bumpRefreshSeed()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
