//
//  SourceDetailView.swift
//  Quotations
//
//  Right-hand pane: opaque background, list of quotations for the selected source.
//

import SwiftData
import SwiftUI

struct SourceDetailView: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?

    @Environment(\.colorScheme) private var colorScheme
    @State private var showQuotationForm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    Label("Add Quotation", systemImage: "text.quote")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add quotation")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.windowBackgroundColor))

            if showQuotationForm {
                QuotationFormView(
                    source: source,
                    onSuccess: { showQuotationForm = false },
                    onCancel: { showQuotationForm = false }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            ScrollView {
                QuotationListView(
                    source: source,
                    searchQuery: searchQuery,
                    quotationIdsFilter: quotationIdsFilter
                )
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
