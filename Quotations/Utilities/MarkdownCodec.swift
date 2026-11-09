//
//  MarkdownCodec.swift
//  Quotations
//

import AppKit
import Foundation
import SwiftUI

/// Minimal markdown codec for quotation text: bold, italic, and newlines only.
enum MarkdownCodec {
    static let quotationFontSize: CGFloat = 16
    /// Matches the SwiftUI `.lineSpacing(6)` used in display mode.
    static let quotationLineSpacing: CGFloat = 6
    static let quotationFont = Font.system(size: quotationFontSize, design: .serif)

    static var quotationBaseFont: NSFont {
        if let serif = NSFont.systemFont(ofSize: quotationFontSize).fontDescriptor.withDesign(.serif) {
            return NSFont(descriptor: serif, size: quotationFontSize) ?? NSFont.systemFont(ofSize: quotationFontSize)
        }
        return NSFont.systemFont(ofSize: quotationFontSize)
    }

    static var quotationParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = quotationLineSpacing
        return style
    }

    /// Default attributes for new text typed into the editor.
    static var editorTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: quotationBaseFont,
            .paragraphStyle: quotationParagraphStyle,
            .foregroundColor: NSColor.textColor
        ]
    }

    // MARK: - Parse

    /// SwiftUI display string with run-level fonts (no line spacing; apply `.lineSpacing` in the view).
    static func attributedString(from markdown: String) -> AttributedString {
        var result = AttributedString()
        for segment in segments(from: markdown) {
            var piece = AttributedString(segment.text)
            piece.font = Font(font(bold: segment.bold, italic: segment.italic))
            result += piece
        }
        return result
    }

    /// AppKit editor string with NSFont runs, matching paragraph spacing, and adaptive color.
    static func editorAttributedString(from markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let paragraph = quotationParagraphStyle
        for segment in segments(from: markdown) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font(bold: segment.bold, italic: segment.italic),
                .paragraphStyle: paragraph,
                .foregroundColor: NSColor.textColor
            ]
            result.append(NSAttributedString(string: segment.text, attributes: attributes))
        }
        return result
    }

    /// Re-maps an arbitrary attributed string (e.g. pasted content) onto the editor's
    /// serif font and paragraph style, preserving only bold/italic traits.
    static func normalizedForEditor(_ source: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(string: source.string)
        let paragraph = quotationParagraphStyle
        let fullRange = NSRange(location: 0, length: (source.string as NSString).length)
        result.addAttributes(
            [.font: quotationBaseFont, .paragraphStyle: paragraph, .foregroundColor: NSColor.textColor],
            range: fullRange
        )
        source.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: source.length),
            options: []
        ) { value, range, _ in
            guard let font = value as? NSFont else { return }
            let traits = font.fontDescriptor.symbolicTraits
            result.addAttribute(
                .font,
                value: self.font(bold: traits.contains(.bold), italic: traits.contains(.italic)),
                range: range
            )
        }
        return result
    }

    // MARK: - Serialize

    static func markdown(from attributedString: NSAttributedString) -> String {
        let string = attributedString.string as NSString
        guard string.length > 0 else { return "" }

        // Merge adjacent runs whose bold/italic traits match (they may differ in other
        // attributes), so `**a**` + `**b**` serializes as `**ab**`, not `**a****b**`.
        var runs: [Segment] = []
        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: string.length),
            options: []
        ) { attributes, range, _ in
            let traits = fontTraits(from: attributes)
            let text = string.substring(with: range)
            if let last = runs.last, last.bold == traits.bold, last.italic == traits.italic {
                runs[runs.count - 1] = Segment(text: last.text + text, bold: traits.bold, italic: traits.italic)
            } else {
                runs.append(Segment(text: text, bold: traits.bold, italic: traits.italic))
            }
        }

        return runs.map { run in
            let marker = (run.bold ? "**" : "") + (run.italic ? "*" : "")
            // Emphasis markers must hug non-whitespace, so keep surrounding whitespace outside.
            let leading = run.text.prefix { $0.isWhitespace }
            let rest = run.text.dropFirst(leading.count)
            let trailing = String(rest.reversed().prefix { $0.isWhitespace }.reversed())
            let core = String(rest.dropLast(trailing.count))
            guard !marker.isEmpty, !core.isEmpty else { return escapeMarkdown(run.text) }
            return escapeMarkdown(String(leading)) + marker + escapeMarkdown(core) + marker + escapeMarkdown(trailing)
        }.joined()
    }

    /// The visible text of stored markdown, with formatting markers and escapes removed.
    static func plainText(from markdown: String) -> String {
        segments(from: markdown).map(\.text).joined()
    }

    /// Backslash-escapes characters that inline markdown would otherwise interpret, so
    /// plain text (e.g. imported highlights) round-trips through `attributedString(from:)`.
    static func escapeMarkdown(_ text: String) -> String {
        var result = ""
        for character in text {
            if "\\*_`[]~<&".contains(character) { result.append("\\") }
            result.append(character)
        }
        return result
    }

    // MARK: - Private

    private struct Segment {
        let text: String
        let bold: Bool
        let italic: Bool
    }

    private static func segments(from markdown: String) -> [Segment] {
        guard !markdown.isEmpty else { return [] }
        let parsed: AttributedString
        do {
            parsed = try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )
        } catch {
            return [Segment(text: markdown, bold: false, italic: false)]
        }

        var result: [Segment] = []
        for run in parsed.runs {
            let text = String(parsed[run.range].characters)
            let intent = run.inlinePresentationIntent
            result.append(
                Segment(
                    text: text,
                    bold: intent?.contains(.stronglyEmphasized) ?? false,
                    italic: intent?.contains(.emphasized) ?? false
                )
            )
        }
        return result
    }

    static func font(bold: Bool, italic: Bool) -> NSFont {
        var font = quotationBaseFont
        let manager = NSFontManager.shared
        if bold { font = manager.convert(font, toHaveTrait: .boldFontMask) }
        if italic { font = manager.convert(font, toHaveTrait: .italicFontMask) }
        return font
    }

    private static func fontTraits(from attributes: [NSAttributedString.Key: Any]) -> (bold: Bool, italic: Bool) {
        guard let font = attributes[.font] as? NSFont else { return (false, false) }
        let traits = font.fontDescriptor.symbolicTraits
        return (traits.contains(.bold), traits.contains(.italic))
    }
}
