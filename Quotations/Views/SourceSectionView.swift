//
//  SourceSectionView.swift
//  Quotations
//
//  Reusable source header + content in the main list style.
//

import SwiftData
import SwiftUI

/// Title + metadata row for a source. Supports a frosted chrome when content scrolls underneath.
struct SourceHeaderView: View {
    let source: Source
    let findQuery: String
    /// When set, tapping the source header clears the selected quotation.
    var selectedQuotationId: Binding<PersistentIdentifier?>? = nil
    /// Frosted / tinted backdrop shown when quotations have scrolled under the header.
    var showsScrolledChrome: Bool = false

    @Environment(\.colorScheme) private var colorScheme

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

    private var titleFontSize: CGFloat {
        showsScrolledChrome ? 16 : 20
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: showsScrolledChrome ? 4 : 6) {
                    HighlightMatch(text: source.title, query: findQuery)
                        .font(.system(size: titleFontSize, weight: .regular, design: .serif))
                        .multilineTextAlignment(.leading)
                    if metadataText != nil || sourceURL != nil {
                        HStack(spacing: 6) {
                            if let metadataText {
                                HighlightMatch(
                                    text: metadataText,
                                    query: findQuery
                                )
                                .font(.system(size: 14))
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
                .padding(.top, showsScrolledChrome ? 0 : 4)
                Spacer()
            }
            .padding(.bottom, showsScrolledChrome ? 8 : 10)
            .padding(.top, showsScrolledChrome ? 6 : 8)
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
        .background { scrolledChromeBackground }
        .overlay(alignment: .bottom) {
            if showsScrolledChrome {
                Divider()
                    .opacity(0.55)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsScrolledChrome)
    }

    @ViewBuilder
    private var scrolledChromeBackground: some View {
        ZStack {
            AppColors.mainBackground(colorScheme: colorScheme)

            if showsScrolledChrome {
                Rectangle()
                    .fill(.ultraThinMaterial)
                AppColors.mainBackground(colorScheme: colorScheme)
                    .opacity(0.55)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

/// One source block: header (title, author, link) and content below.
struct SourceSectionView<BelowContent: View>: View {
    let source: Source
    let findQuery: String
    /// When set, tapping the source header clears the selected quotation.
    var selectedQuotationId: Binding<PersistentIdentifier?>? = nil
    /// When false, section background is transparent (parent provides parchment).
    var showsBackground: Bool = true
    /// Frosted chrome on the header (used when the header is pinned while scrolling).
    var showsScrolledChrome: Bool = false

    @ViewBuilder let belowContent: () -> BelowContent

    @Environment(\.colorScheme) private var colorScheme

    private var parchmentBackground: Color {
        AppColors.mainBackground(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SourceHeaderView(
                source: source,
                findQuery: findQuery,
                selectedQuotationId: selectedQuotationId,
                showsScrolledChrome: showsScrolledChrome
            )

            belowContent()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(showsBackground ? parchmentBackground : Color.clear)
    }
}
