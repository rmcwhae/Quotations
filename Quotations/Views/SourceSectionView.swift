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

/// One source block: header (title, author, optional Add Quotation plus), optional form when plus is clicked, divider, and content below.
/// When `showQuotationForm` binding is provided (e.g. from detail toolbar), the header has no button. When nil, the header shows a plus to add a quotation.
struct SourceSectionView<BelowContent: View>: View {
    let source: Source
    let searchQuery: String
    var quotationIdsFilter: Set<PersistentIdentifier>?
    /// When set (e.g. to parent horizontal padding), the header is inset so its background extends to the edges.
    var headerOutset: CGFloat = 0
    /// When non-nil, form visibility is driven by this binding and no add-quotation button is shown in the header (e.g. detail view uses toolbar plus). When nil, local state and a plus button in the header are used.
    var showQuotationForm: Binding<Bool>? = nil

    @ViewBuilder let belowContent: (Binding<Bool>) -> BelowContent

    @State private var showQuotationFormLocal = false

    private var formVisibility: Binding<Bool> {
        if let showQuotationForm { return showQuotationForm }
        return Binding(
            get: { showQuotationFormLocal },
            set: { showQuotationFormLocal = $0 }
        )
    }

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
                    if showQuotationForm == nil {
                        Button {
                            formVisibility.wrappedValue = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add quotation")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sourceSectionBackgroundColor())
            .padding(.horizontal, headerOutset > 0 ? -headerOutset : 0)

            Divider()

            belowContent(formVisibility)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
