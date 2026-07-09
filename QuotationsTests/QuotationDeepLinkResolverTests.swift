//
//  QuotationDeepLinkResolverTests.swift
//  QuotationsTests
//

import SwiftData
import XCTest
@testable import Quotations

final class QuotationDeepLinkResolverTests: XCTestCase {
    func testResolvesQuotationAcrossSeparateModelContainers() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deeplink-resolver-\(UUID().uuidString).store")

        let schema = Schema([Author.self, Source.self, Quotation.self])
        let configuration = ModelConfiguration(AppGroupStore.configurationName, schema: schema, url: storeURL)

        let writerContainer = try ModelContainer(for: schema, configurations: [configuration])
        let writerContext = ModelContext(writerContainer)
        let author = Author(name: "Plato")
        let source = Source(title: "Republic", author: author)
        let quotation = Quotation(content: "Justice is virtue and order", source: source)
        writerContext.insert(author)
        writerContext.insert(source)
        writerContext.insert(quotation)
        try writerContext.save()

        let encodedQuotationID = try XCTUnwrap(QuotationDeepLink.encode(quotation.persistentModelID))
        let encodedSourceID = try XCTUnwrap(QuotationDeepLink.encode(source.persistentModelID))

        let readerContainer = try ModelContainer(for: schema, configurations: [configuration])
        let readerContext = ModelContext(readerContainer)

        let resolved = try XCTUnwrap(
            QuotationDeepLinkResolver.quotation(encodedID: encodedQuotationID, in: readerContext)
        )
        XCTAssertEqual(resolved.content, quotation.content)

        let resolvedSourceID = try XCTUnwrap(
            QuotationDeepLinkResolver.sourceID(
                encodedID: encodedSourceID,
                for: resolved,
                in: readerContext
            )
        )
        XCTAssertEqual(
            QuotationDeepLink.uriRepresentation(for: resolvedSourceID),
            QuotationDeepLink.uriRepresentation(for: source.persistentModelID)
        )
    }

    /// Mirrors widget timeline encoding in one process and app resolution in another.
    func testResolvesWidgetDeepLinkURLAcrossSeparateModelContainers() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-deeplink-\(UUID().uuidString).store")

        let schema = Schema([Author.self, Source.self, Quotation.self])
        let configuration = ModelConfiguration(AppGroupStore.configurationName, schema: schema, url: storeURL)

        let writerContainer = try ModelContainer(for: schema, configurations: [configuration])
        let writerContext = ModelContext(writerContainer)
        let author = Author(name: "Aristotle")
        let source = Source(title: "Nicomachean Ethics", author: author)
        let quotation = Quotation(content: "We are what we repeatedly do", source: source)
        writerContext.insert(author)
        writerContext.insert(source)
        writerContext.insert(quotation)
        try writerContext.save()

        let widgetURL = try XCTUnwrap(
            QuotationDeepLink.url(
                for: .quotation(quotation.persistentModelID, sourceID: source.persistentModelID)
            )
        )
        XCTAssertTrue(QuotationDeepLink.isQuotationDeepLink(widgetURL))

        let readerContainer = try ModelContainer(for: schema, configurations: [configuration])
        let readerContext = ModelContext(readerContainer)

        let parameters = try XCTUnwrap(QuotationDeepLink.parseURLParameters(widgetURL))
        let resolvedQuotation = try XCTUnwrap(
            QuotationDeepLinkResolver.quotation(encodedID: parameters.encodedQuotationID, in: readerContext)
        )
        let resolvedSourceID = try XCTUnwrap(
            QuotationDeepLinkResolver.sourceID(
                encodedID: parameters.encodedSourceID,
                for: resolvedQuotation,
                in: readerContext
            )
        )

        XCTAssertEqual(
            QuotationDeepLink.uriRepresentation(for: resolvedQuotation.persistentModelID),
            QuotationDeepLink.uriRepresentation(for: quotation.persistentModelID)
        )
        XCTAssertEqual(
            QuotationDeepLink.uriRepresentation(for: resolvedSourceID),
            QuotationDeepLink.uriRepresentation(for: source.persistentModelID)
        )
    }
}
