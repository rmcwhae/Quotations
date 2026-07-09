//
//  ModelContext+Save.swift
//  Quotations
//

import Foundation
import SwiftData
import WidgetKit

extension ModelContext {
    /// Saves pending changes and notifies observers (e.g. search refresh).
    func saveAndNotify() throws {
        try save()
        NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
        WidgetCenter.shared.reloadAllTimelines()
        QuotationSearchIndexManager.scheduleSync(modelContext: self)
    }
}
