//
//  SourceSectionView.swift
//  Quotations
//
//  Reusable source header + divider + content in the main list style.
//

import SwiftData
import SwiftUI

/// One source block: header (title, author, link), divider, and content below.
struct SourceSectionView<BelowContent: View>: View {
    let source: Source
    let searchQuery: String
    /// When set, tapping the source header clears the selected quotation.
    var selectedQuotationId: Binding<PersistentIdentifier?>? = nil
    /// When false, section background is transparent (parent provides parchment).
    var showsBackground: Bool = true

    @ViewBuilder let belowContent: () -> BelowContent

    @Environment(\.colorScheme) private var colorScheme

    private var parchmentBackground: Color {
        AppColors.mainBackground(colorScheme: colorScheme)
    }

    private var sourceURL: URL? {
        guard let urlString = source.url, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    /// "Author (Year) • Format • Date read", omitting any missing pieces.
    private var metadataText: String? {
        var components: [String] = []
        if let author = source.author {
            components.append(author.name + (source.publicationYear.map { " (\($0))" } ?? ""))
        }
        if let format = source.format, !format.isEmpty {
            components.append(format)
        }
        if let dateRead = source.formattedDateRead {
            components.append(dateRead)
        }
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HighlightMatch(text: source.title, query: searchQuery)
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .multilineTextAlignment(.leading)
                        if metadataText != nil || sourceURL != nil {
                            HStack(spacing: 6) {
                                if let metadataText {
                                    HighlightMatch(
                                        text: metadataText,
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
                }
                .padding(.bottom, 2)
                .padding(.leading, 28)
                .padding(.trailing, 16)
                .frame(maxWidth: LayoutMetrics.quotationColumnMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedQuotationId?.wrappedValue = nil
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            belowContent()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(showsBackground ? parchmentBackground : Color.clear)
    }
}
