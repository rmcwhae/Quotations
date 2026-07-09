//
//  QuotationWidgetDataStore.swift
//  QuotationsWidget
//

import Foundation
import SwiftData

struct WidgetQuotationSnapshot: Identifiable {
    let quotationID: PersistentIdentifier
    let sourceID: PersistentIdentifier?
    let content: String
    let authorName: String?
    let sourceTitle: String?

    var id: String {
        String(describing: quotationID)
    }
}

enum QuotationWidgetDataStore {
    static func fetchEligibleQuotations() -> [WidgetQuotationSnapshot] {
        let schema = Schema([Author.self, Source.self, Quotation.self])
        let configuration = AppGroupStore.modelConfiguration(schema: schema)

        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else {
            return []
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Quotation>(
            predicate: #Predicate { $0.deletedAt == nil }
        )

        guard let quotations = try? context.fetch(descriptor) else { return [] }

        return quotations
            .filter { QuotationWidgetFilter.isEligibleForWidget($0.content) }
            .map { quotation in
                WidgetQuotationSnapshot(
                    quotationID: quotation.persistentModelID,
                    sourceID: quotation.source?.persistentModelID,
                    content: quotation.content,
                    authorName: quotation.source?.author?.name,
                    sourceTitle: quotation.source?.title
                )
            }
    }
}
