//
//  ModelContext+Save.swift
//  Quotations
//

import Foundation
import SwiftData

extension ModelContext {
    /// Saves pending changes and notifies observers (e.g. search refresh).
    func saveAndNotify() throws {
        try save()
        NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
    }
}
