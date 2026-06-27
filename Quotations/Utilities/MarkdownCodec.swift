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

    // MARK: - Serialize

    static func markdown(from attributedString: NSAttributedString) -> String {
        let string = attributedString.string
        guard !string.isEmpty else { return "" }

        var result = ""
        var index = 0

        while index < attributedString.length {
            var effectiveRange = NSRange(location: 0, length: 0)
            let attributes = attributedString.attributes(at: index, effectiveRange: &effectiveRange)
            let substring = (string as NSString).substring(with: effectiveRange)
            let traits = fontTraits(from: attributes)

            if traits.bold && traits.italic {
                result += "***\(substring)***"
            } else if traits.bold {
                result += "**\(substring)**"
            } else if traits.italic {
                result += "*\(substring)*"
            } else {
                result += substring
            }

            index = effectiveRange.location + effectiveRange.length
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
