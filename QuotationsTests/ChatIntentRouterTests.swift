//
//  ChatIntentRouterTests.swift
//  QuotationsTests
//

import XCTest
@testable import Quotations

final class ChatIntentRouterTests: XCTestCase {
    func testStylisticProfileRoutesToLibraryProfile() {
        XCTAssertEqual(
            ChatIntentRouter.intent(for: "Generate a stylistic profile of my library"),
            .libraryProfile
        )
    }

    func testRecurringThemesRoutesToLibraryProfile() {
        XCTAssertEqual(
            ChatIntentRouter.intent(for: "What recurring themes appear in my library?"),
            .libraryProfile
        )
    }

    func testSpecificQuestionRoutesToQuestionSpecific() {
        XCTAssertEqual(
            ChatIntentRouter.intent(for: "Quotes about mortality and grief"),
            .questionSpecific
        )
    }

    func testSuggestedAuthorPromptRoutesToLibraryProfile() {
        XCTAssertEqual(
            ChatIntentRouter.intent(for: ChatSuggestedPrompt.topAuthors.message),
            .libraryProfile
        )
    }
}
