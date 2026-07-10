//
//  StopWordsStoreTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class StopWordsStoreTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "StopWordsStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSeedsDefaultsWhenUserDefaultsKeyAbsent() {
        let store = StopWordsStore(userDefaults: userDefaults)

        XCTAssertEqual(Set(store.words), EnglishStopwords.defaultWords)
        XCTAssertEqual(userDefaults.stringArray(forKey: StopWordsStore.userDefaultsKey), store.words)
    }

    func testPersistsAddAndRemoveAcrossInstances() {
        let initial = StopWordsStore(userDefaults: userDefaults)
        initial.addWord("freedom")

        let reloaded = StopWordsStore(userDefaults: userDefaults)
        XCTAssertTrue(reloaded.words.contains("freedom"))

        reloaded.removeWord("freedom")
        let final = StopWordsStore(userDefaults: userDefaults)
        XCTAssertFalse(final.words.contains("freedom"))
    }

    func testNormalizesCasingAndWhitespaceAndDedupes() {
        let store = StopWordsStore(userDefaults: userDefaults)
        let initialCount = store.words.count

        store.addWord("  Freedom  ")
        store.addWord("FREEDOM")

        XCTAssertEqual(store.words.filter { $0 == "freedom" }.count, 1)
        XCTAssertEqual(store.words.count, initialCount + 1)
    }

    func testResetToDefaultsRestoresBuiltInList() {
        let store = StopWordsStore(userDefaults: userDefaults)
        store.removeWord("the")
        store.addWord("customword")

        store.resetToDefaults()

        XCTAssertEqual(Set(store.words), EnglishStopwords.defaultWords)
        XCTAssertTrue(store.words.contains("the"))
        XCTAssertFalse(store.words.contains("customword"))
    }
}
