//
//  ModelContext+Save.swift
//  Quotations
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

extension ModelContext {
    /// Saves pending changes and notifies observers (e.g. search refresh).
    func saveAndNotify() throws {
        try save()
        NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
        if LibraryModeController.isDemoModeActive {
            // Keep in-app search fresh and allow ephemeral demo embedding sync,
            // but never reload the widget or write Spotlight / on-disk embeddings.
            QuotationSearchIndexManager.scheduleSync(modelContext: self)
            return
        }
        WidgetCenter.shared.reloadAllTimelines()
        QuotationSearchIndexManager.scheduleSync(modelContext: self)
    }
}

extension EnvironmentValues {
    /// Shows a save/delete failure to the user. ContentView wires this to its error alert.
    @Entry var reportEditError: (String) -> Void = { _ in }
}
