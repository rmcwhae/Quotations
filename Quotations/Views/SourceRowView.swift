//
//  SourceRowView.swift
//  Quotations
//

import SwiftData
import SwiftUI

struct SourceRowView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    @Binding var selectedQuotationId: PersistentIdentifier?

    @State private var showQuotationForm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let urlString = source.url, !urlString.isEmpty, let url = URL(string: urlString) {
                        Link(destination: url) {
                            HighlightMatch(text: source.title, query: searchQuery)
                        }
                        .font(.title2)
                    } else {
                        HighlightMatch(text: source.title, query: searchQuery)
                            .font(.title2)
                    }

                    if let author = source.author {
                        HighlightMatch(
                            text: author.name + (source.publicationYear.map { " (\($0))" } ?? ""),
                            query: searchQuery
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    showQuotationForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add quotation")
            }

            QuotationListView(
                source: source,
                searchQuery: searchQuery,
                quotationIdsFilter: quotationIdsFilter,
                selectedQuotationId: $selectedQuotationId,
                showQuotationForm: $showQuotationForm
            )
        }
        .frame(maxWidth: 700, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
