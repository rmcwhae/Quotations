//
//  QuotationWidgetView.swift
//  QuotationsWidget
//

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
        case .systemMedium: 6
        default: nil
        }
    }

    var body: some View {
        Group {
            if let content = entry.content {
                quotationContent(content)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(entry.deepLinkURL)
        .containerBackground(backgroundColor, for: .widget)
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
    }

    private var bodyFontSize: CGFloat {
        family == .systemSmall ? 13 : 15
    }

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
