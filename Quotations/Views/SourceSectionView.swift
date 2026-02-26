//
//  SourceSectionView.swift
//  Quotations
//
//  Reusable source header + divider + content in the main list style.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Background color used for the source header block in both detail and search.
private func sourceSectionBackgroundColor() -> Color {
    #if os(macOS)
    Color(nsColor: .windowBackgroundColor)
    #else
    Color(uiColor: .systemBackground)
    #endif
}

/// One source block: header (title, author, Add Quotation), optional form, divider, and custom content below.
struct SourceSectionView<BelowContent: View>: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    /// When set (e.g. to parent horizontal padding), the header is inset so its background extends to the edges.
    var headerOutset: CGFloat = 0

    @ViewBuilder let belowContent: () -> BelowContent

    @State private var showQuotationForm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            .background(sourceSectionBackgroundColor())
            .padding(.horizontal, headerOutset > 0 ? -headerOutset : 0)

            Divider()

            belowContent()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
