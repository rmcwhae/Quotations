//
//  WidgetRefreshStore.swift
//  Quotations
//

import Foundation

enum WidgetRefreshStore {
    private static let refreshSeedKey = "widgetRefreshSeed"

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupStore.identifier)
    }

    static var refreshSeed: UInt64 {
        let value = userDefaults?.integer(forKey: refreshSeedKey) ?? 0
        return UInt64(bitPattern: Int64(value))
    }

    static func bumpRefreshSeed() {
        let next = refreshSeed &+ 1
        userDefaults?.set(Int(bitPattern: UInt(next)), forKey: refreshSeedKey)
    }
}
