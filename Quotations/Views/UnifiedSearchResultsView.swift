//
//  UnifiedSearchResultsView.swift
//  Quotations
//
//  Right-hand pane when searching: all matching sources shown in one scrollable view.
//

import SwiftData
import SwiftUI

struct UnifiedSearchResultsView: View {
    let sources: [Source]
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?

    private let horizontalPadding: CGFloat = 16

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    SingleSourceSearchSection(
                        source: source,
                        searchQuery: searchQuery,
                        quotationIdsFilter: quotationIdsFilter,
                        horizontalPadding: horizontalPadding
                    )
                    if index < sources.count - 1 {
                        Divider()
                            .padding(.vertical, 16)
                    }
                }
            }
            .padding(horizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SingleSourceSearchSection: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    var horizontalPadding: CGFloat

    @Environment(\.colorScheme) private var colorScheme
    @State private var showQuotationForm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header block: full-width background with grey border above and below
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

                if showQuotationForm {
                    QuotationFormView(
                        source: source,
                        onSuccess: { showQuotationForm = false },
                        onCancel: { showQuotationForm = false }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorScheme == .dark ? Color(white: 0.12) : Color.white)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.gray.opacity(0.4))
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.gray.opacity(0.4))
                    .frame(height: 1)
            }
            .padding(.horizontal, -horizontalPadding)

            QuotationListView(
                source: source,
                searchQuery: searchQuery,
                quotationIdsFilter: quotationIdsFilter
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
