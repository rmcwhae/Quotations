//
//  SourceSectionView.swift
//  Quotations
//
//  Reusable source header + divider + content in the main list style.
//

import SwiftData
import SwiftUI


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
    /// When false, hides the header add-quotation button (e.g. search results).
    var showsAddButton: Bool = true

    @ViewBuilder let belowContent: (Binding<Bool>) -> BelowContent

    @Environment(\.colorScheme) private var colorScheme
    @State private var showQuotationFormLocal = false

    private var parchmentBackground: Color {
        AppColors.mainBackground(colorScheme: colorScheme)
    }

    private var sourceURL: URL? {
        guard let urlString = source.url, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

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
                    VStack(alignment: .leading, spacing: 6) {
                        HighlightMatch(text: source.title, query: searchQuery)
                            .font(.system(size: 30, weight: .regular, design: .serif))
                            .multilineTextAlignment(.leading)
                        if source.author != nil || sourceURL != nil {
                            HStack(spacing: 6) {
                                if let author = source.author {
                                    HighlightMatch(
                                        text: author.name + (source.publicationYear.map { " (\($0))" } ?? ""),
                                        query: searchQuery
                                    )
                                    .font(.system(size: 14, design: .serif).italic())
                                    .foregroundStyle(.secondary)
                                }
                                if let url = sourceURL {
                                    Link(destination: url) {
                                        Image(systemName: "link")
                                    }
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Open source link")
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    Spacer()
                    if showQuotationForm == nil && showsAddButton {
                        Button {
                            formVisibility.wrappedValue = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add quotation")
                    }
                }
                .padding(.vertical, 16)
                .padding(.leading, 28)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, headerOutset > 0 ? -headerOutset : 0)

            Divider()

            belowContent(formVisibility)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(parchmentBackground)
    }
}
