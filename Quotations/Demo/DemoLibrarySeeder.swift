//
//  DemoLibrarySeeder.swift
//  Quotations
//

import Foundation
import SwiftData

enum DemoLibrarySeeder {
    static func makeContainer(schema: Schema = Schema([Author.self, Source.self, Quotation.self])) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        try seed(into: ModelContext(container))
        return container
    }

    static func seed(into context: ModelContext, catalog: [DemoCatalog.SourceSeed] = DemoCatalog.sources) throws {
        var authorsByName: [String: Author] = [:]

        for sourceSeed in catalog {
            let author: Author
            if let existing = authorsByName[sourceSeed.authorName] {
                author = existing
            } else {
                let created = Author(name: sourceSeed.authorName)
                context.insert(created)
                authorsByName[sourceSeed.authorName] = created
                author = created
            }

            let source = Source(
                title: sourceSeed.title,
                author: author,
                publicationYear: sourceSeed.publicationYear,
                format: sourceSeed.format
            )
            context.insert(source)

            for quotationSeed in sourceSeed.quotations {
                let quotation = Quotation(
                    content: quotationSeed.content,
                    source: source,
                    location: quotationSeed.location
                )
                context.insert(quotation)
            }
        }

        try context.save()
    }
}
