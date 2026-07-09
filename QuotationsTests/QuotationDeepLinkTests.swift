//
//  QuotationDeepLinkTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class QuotationDeepLinkTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Author.self, Source.self, Quotation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testRoundTripsQuotationDeepLink() throws {
        let author = Author(name: "Plato")
        let source = Source(title: "Republic", author: author)
        let quotation = Quotation(content: "Justice is virtue and order", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()

        let url = try XCTUnwrap(
            QuotationDeepLink.url(
                for: .quotation(quotation.persistentModelID, sourceID: source.persistentModelID)
            )
        )
        let route = try XCTUnwrap(QuotationDeepLink.parse(url))

        guard case .quotation(let quotationID, let sourceID) = route else {
            return XCTFail("Expected quotation route")
        }
        XCTAssertEqual(
            QuotationDeepLink.uriRepresentation(for: quotationID),
            QuotationDeepLink.uriRepresentation(for: quotation.persistentModelID)
        )
        XCTAssertEqual(
            QuotationDeepLink.uriRepresentation(for: try XCTUnwrap(sourceID)),
            QuotationDeepLink.uriRepresentation(for: source.persistentModelID)
        )

        XCTAssertEqual(
            QuotationDeepLink.encode(quotation.persistentModelID),
            QuotationDeepLink.encode(quotationID)
        )
    }

    func testParsesHomeDeepLink() {
        XCTAssertEqual(QuotationDeepLink.parseIncomingURL(URL(string: "quotations://")!), .home)
        XCTAssertEqual(QuotationDeepLink.parseIncomingURL(URL(string: "quotations://open")!), .home)
    }

    func testBuildsOpenQuotationURLWithPath() throws {
        let author = Author(name: "Plato")
        let source = Source(title: "Republic", author: author)
        let quotation = Quotation(content: "Justice is virtue and order", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()

        let url = try XCTUnwrap(
            QuotationDeepLink.url(
                for: .quotation(quotation.persistentModelID, sourceID: source.persistentModelID)
            )
        )
        XCTAssertEqual(url.host, "open")
        XCTAssertEqual(url.path, "/quotation")

        let parameters = try XCTUnwrap(QuotationDeepLink.parseURLParameters(url))
        let resolved = try XCTUnwrap(
            QuotationDeepLinkResolver.quotation(encodedID: parameters.encodedQuotationID, in: context)
        )
        XCTAssertEqual(resolved.persistentModelID, quotation.persistentModelID)
    }

    func testEncodedTokensMatchAcrossSeparateModelContainers() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deeplink-token-\(UUID().uuidString).store")

        let schema = Schema([Author.self, Source.self, Quotation.self])
        let configuration = ModelConfiguration("Quotations", schema: schema, url: storeURL)

        let writerContainer = try ModelContainer(for: schema, configurations: [configuration])
        let writerContext = ModelContext(writerContainer)
        let quotation = Quotation(content: "Justice is virtue and order")
        writerContext.insert(quotation)
        try writerContext.save()

        let encodedInWriter = try XCTUnwrap(QuotationDeepLink.encode(quotation.persistentModelID))

        let readerContainer = try ModelContainer(for: schema, configurations: [configuration])
        let readerContext = ModelContext(readerContainer)
        let fetched = try XCTUnwrap(QuotationDeepLinkResolver.quotation(encodedID: encodedInWriter, in: readerContext))

        XCTAssertEqual(
            QuotationDeepLink.encode(fetched.persistentModelID),
            encodedInWriter
        )
    }

    func testMatchesEntityReferenceRegardlessOfStoreIdentifier() throws {
        let author = Author(name: "Plato")
        let source = Source(title: "Republic", author: author)
        let quotation = Quotation(content: "Justice is virtue and order", source: source)
        context.insert(author)
        context.insert(source)
        context.insert(quotation)
        try context.save()

        let fullURI = try XCTUnwrap(QuotationDeepLink.uriRepresentation(for: quotation.persistentModelID))
        let primaryKey = try XCTUnwrap(fullURI.split(separator: "/").last.map(String.init))
        let widgetStyleToken = base64URLToken(for: "x-coredata://Quotation/\(primaryKey)")

        let resolved = try XCTUnwrap(
            QuotationDeepLinkResolver.quotation(encodedID: widgetStyleToken, in: context)
        )
        XCTAssertEqual(resolved.persistentModelID, quotation.persistentModelID)
    }

    func testParseIncomingURLAcceptsQueryOnlyURLs() throws {
        let quotation = Quotation(content: "one two three four five")
        context.insert(quotation)
        try context.save()

        let encoded = try XCTUnwrap(QuotationDeepLink.encode(quotation.persistentModelID))
        let url = try XCTUnwrap(URL(string: "quotations://?id=\(encoded)"))
        let route = try XCTUnwrap(QuotationDeepLink.parseIncomingURL(url))

        guard case .quotation(let quotationID, _) = route else {
            return XCTFail("Expected quotation route")
        }
        XCTAssertEqual(
            QuotationDeepLink.uriRepresentation(for: quotationID),
            QuotationDeepLink.uriRepresentation(for: quotation.persistentModelID)
        )
    }

    private func base64URLToken(for uri: String) -> String {
        Data(uri.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
