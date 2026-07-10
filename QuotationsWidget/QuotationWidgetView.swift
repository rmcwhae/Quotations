//
//  QuotationWidgetView.swift
//  QuotationsWidget
//

import AppIntents
import SwiftUI
import WidgetKit

struct QuotationWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    let entry: QuotationWidgetEntry

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.10, blue: 0.07)
            : Color(red: 0.995, green: 0.99, blue: 0.985)
    }

    private var lineLimit: Int? {
        switch family {
        case .systemSmall: 4
        default: nil
        }
    }

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumWidgetContent
            } else {
                overlayWidgetContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(backgroundColor, for: .widget)
    }

    @ViewBuilder
    private var mediumWidgetContent: some View {
        let content = Group {
            if let body = entry.content {
                mediumQuotationContent(body)
            } else {
                mediumEmptyState
            }
        }

        if let url = entry.deepLinkURL, QuotationDeepLink.isQuotationDeepLink(url) {
            Link(destination: url) {
                content
            }
            .widgetURL(url)
        } else {
            content
        }
    }

    @ViewBuilder
    private var overlayWidgetContent: some View {
        ZStack(alignment: .bottomTrailing) {
            let content = Group {
                if let body = entry.content {
                    quotationContent(body)
                } else {
                    emptyState
                }
            }

            if let url = entry.deepLinkURL, QuotationDeepLink.isQuotationDeepLink(url) {
                Link(destination: url) {
                    content
                }
                .widgetURL(url)
            } else {
                content
            }

            refreshButton
        }
    }

    private var refreshButton: some View {
        Button(intent: RefreshQuotationWidgetIntent()) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Refresh quotation")
    }

    private var mediumRefreshButton: some View {
        Button(intent: RefreshQuotationWidgetIntent()) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Refresh quotation")
    }

    private func mediumQuotationContent(_ content: String) -> some View {
        GeometryReader { geometry in
            let horizontalInset = mediumHorizontalPadding
            let topInset = mediumTopPadding
            let bottomInset = mediumBottomPadding
            let footerHeight = mediumFooterHeight
            let contentWidth = max(0, geometry.size.width - horizontalInset * 2)
            let textHeight = max(
                0,
                geometry.size.height - topInset - bottomInset - footerHeight
            )
            let fontSize = mediumFontSize(forAvailableHeight: textHeight)
            let maxLines = mediumMaxLines(forAvailableHeight: textHeight, fontSize: fontSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(displayText(from: content))
                    .font(.system(size: fontSize, design: .serif))
                    .foregroundStyle(.primary)
                    .lineSpacing(0)
                    .lineLimit(maxLines, reservesSpace: false)
                    .multilineTextAlignment(.leading)
                    .frame(width: contentWidth, height: textHeight, alignment: .topLeading)
                    .clipped()
                    .invalidatableContent()

                mediumFooterRow
                    .frame(width: contentWidth, height: footerHeight, alignment: .leading)
            }
            .padding(.horizontal, horizontalInset)
            .padding(.top, topInset)
            .padding(.bottom, bottomInset)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }

    private func mediumFontSize(forAvailableHeight height: CGFloat) -> CGFloat {
        let lineHeightRatio: CGFloat = 1.16
        let targetLines: CGFloat = 6
        let computed = height / targetLines / lineHeightRatio
        return min(max(computed, 10), 16)
    }

    private func mediumMaxLines(forAvailableHeight height: CGFloat, fontSize: CGFloat) -> Int {
        let lineHeight = fontSize * 1.16
        guard lineHeight > 0 else { return 1 }
        return max(1, Int(floor(height / lineHeight)))
    }

    private var mediumFooterRow: some View {
        HStack(alignment: .center, spacing: 8) {
            if let attribution = attributionLabel {
                Text(attribution)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .invalidatableContent()
            } else {
                Spacer(minLength: 0)
            }

            mediumRefreshButton
        }
    }

    private func quotationContent(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayText(from: content))
                .font(.system(size: bodyFontSize, design: .serif))
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
                .invalidatableContent()

            if entry.authorName != nil || entry.sourceTitle != nil {
                attribution
                    .invalidatableContent()
            }
        }
        .padding(12)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private var attribution: some View {
        HStack(spacing: 4) {
            if let author = entry.authorName {
                Text(author)
                    .lineLimit(1)
            }
            if entry.authorName != nil, entry.sourceTitle != nil {
                Text("·")
                    .foregroundStyle(.tertiary)
            }
            if let source = entry.sourceTitle {
                Text(source)
                    .lineLimit(1)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
    }

    private var attributionLabel: String? {
        switch (entry.authorName, entry.sourceTitle) {
        case let (author?, source?):
            return "\(author) · \(source)"
        case let (author?, nil):
            return author
        case let (nil, source?):
            return source
        default:
            return nil
        }
    }

    private var mediumEmptyState: some View {
        GeometryReader { geometry in
            let horizontalInset = mediumHorizontalPadding
            let topInset = mediumTopPadding
            let bottomInset = mediumBottomPadding
            let footerHeight = mediumFooterHeight
            let contentWidth = max(0, geometry.size.width - horizontalInset * 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("No quotations yet")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.primary)
                Text("Add quotations to your library with at least five words and a single paragraph.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                mediumFooterRow
                    .frame(width: contentWidth, height: footerHeight, alignment: .leading)
            }
            .padding(.horizontal, horizontalInset)
            .padding(.top, topInset)
            .padding(.bottom, bottomInset)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No quotations yet")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(.primary)
            Text("Add quotations to your library with at least five words and a single paragraph.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private var bodyFontSize: CGFloat {
        family == .systemSmall ? 13 : 15
    }

    private var mediumHorizontalPadding: CGFloat { 24 }

    private var mediumTopPadding: CGFloat { 22 }

    private var mediumBottomPadding: CGFloat { 18 }

    private var mediumFooterHeight: CGFloat { 12 }

    private func displayText(from markdown: String) -> AttributedString {
        let plain = QuotationWidgetFilter.plainText(from: markdown)
        if let attributed = try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ), !String(attributed.characters).isEmpty {
            return attributed
        }
        return AttributedString(plain)
    }
}

#Preview(as: .systemMedium) {
    QuotationWidget()
} timeline: {
    QuotationWidgetEntry.placeholder
    QuotationWidgetEntry.empty
}
