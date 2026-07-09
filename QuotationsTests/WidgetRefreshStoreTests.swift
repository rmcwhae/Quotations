//
//  WidgetRefreshStoreTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class WidgetRefreshStoreTests: XCTestCase {
    override func tearDown() {
        UserDefaults(suiteName: AppGroupStore.identifier)?
            .removeObject(forKey: "widgetRefreshSeed")
        super.tearDown()
    }

    func testBumpRefreshSeedIncrements() {
        XCTAssertEqual(WidgetRefreshStore.refreshSeed, 0)
        WidgetRefreshStore.bumpRefreshSeed()
        XCTAssertEqual(WidgetRefreshStore.refreshSeed, 1)
        WidgetRefreshStore.bumpRefreshSeed()
        XCTAssertEqual(WidgetRefreshStore.refreshSeed, 2)
    }
}
