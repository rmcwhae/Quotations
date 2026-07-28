//
//  KoboAnnotationsParser.swift
//  Quotations
//

import Foundation

struct KoboAnnotationHighlight: Equatable {
    let content: String
    let location: String?
    let highlightColor: String?
}

struct KoboAnnotationsExport: Equatable {
    let title: String
    let author: String
    let expectedHighlightCount: Int?
    let exportedDateDescription: String?
    let highlights: [KoboAnnotationHighlight]
}

enum KoboAnnotationsParser {
    private static let chapterPattern = /^Chapter (\d+):\s*(.*)$/
    private static let highlightPattern = /^Highlight \(([^)]+)\)$/
    private static let statsPattern = /^(\d+) Highlights\s*\|\s*Exported (.+)$/

    static func parse(text: String) throws -> KoboAnnotationsExport {
        let lines = normalizedLines(from: text)
        var index = 0

        let title = try readRequiredField(
            in: lines,
            index: &index,
            missingMessage: "Kobo export must start with a book title."
        )
        let author = try readRequiredField(
            in: lines,
            index: &index,
            missingMessage: "Kobo export is missing an author name."
        )
        let stats = readOptionalStats(in: lines, index: &index)
        let highlights = parseHighlights(in: lines, startingAt: index)

        guard !highlights.isEmpty else {
            throw KoboAnnotationsImportError.invalidFormat(
                "Kobo export does not contain any highlights."
            )
        }

        return KoboAnnotationsExport(
            title: title,
            author: author,
            expectedHighlightCount: stats?.count,
            exportedDateDescription: stats?.dateDescription,
            highlights: highlights
        )
    }

    static func parse(data: Data) throws -> KoboAnnotationsExport {
        guard let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16) else {
            throw KoboAnnotationsImportError.invalidFormat(
                "Kobo export could not be decoded as text."
            )
        }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw KoboAnnotationsImportError.emptyFile
        }
        return try parse(text: text)
    }
}

private extension KoboAnnotationsParser {
    static func normalizedLines(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    static func readRequiredField(
        in lines: [String],
        index: inout Int,
        missingMessage: String
    ) throws -> String {
        skipBlankLines(in: lines, index: &index)
        guard index < lines.count else {
            if missingMessage.contains("title") {
                throw KoboAnnotationsImportError.emptyFile
            }
            throw KoboAnnotationsImportError.invalidFormat(missingMessage)
        }
        let value = normalizeWhitespace(lines[index])
        guard !value.isEmpty else {
            throw KoboAnnotationsImportError.invalidFormat(missingMessage)
        }
        index += 1
        return value
    }

    static func readOptionalStats(
        in lines: [String],
        index: inout Int
    ) -> (count: Int, dateDescription: String)? {
        skipBlankLines(in: lines, index: &index)
        guard index < lines.count,
              let match = lines[index].firstMatch(of: statsPattern) else {
            return nil
        }
        let count = Int(match.1)
        let dateDescription = String(match.2)
        index += 1
        return count.map { ($0, dateDescription) }
    }

    static func parseHighlights(
        in lines: [String],
        startingAt startIndex: Int
    ) -> [KoboAnnotationHighlight] {
        var index = startIndex
        var currentLocation: String?
        var highlights: [KoboAnnotationHighlight] = []

        while index < lines.count {
            let line = normalizeWhitespace(lines[index])
            if line.isEmpty {
                index += 1
                continue
            }

            if let match = line.firstMatch(of: chapterPattern) {
                currentLocation = "Chapter \(match.1)"
                index += 1
                continue
            }

            if let match = line.firstMatch(of: highlightPattern) {
                index += 1
                if let highlight = readHighlightBody(
                    in: lines,
                    index: &index,
                    color: String(match.1),
                    location: currentLocation
                ) {
                    highlights.append(highlight)
                }
                continue
            }

            index += 1
        }

        return highlights
    }

    static func readHighlightBody(
        in lines: [String],
        index: inout Int,
        color: String,
        location: String?
    ) -> KoboAnnotationHighlight? {
        var bodyLines: [String] = []
        while index < lines.count {
            let bodyLine = normalizeWhitespace(lines[index])
            if bodyLine.isEmpty {
                break
            }
            if bodyLine.firstMatch(of: chapterPattern) != nil
                || bodyLine.firstMatch(of: highlightPattern) != nil {
                break
            }
            bodyLines.append(bodyLine)
            index += 1
        }

        let content = bodyLines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return nil }

        return KoboAnnotationHighlight(
            content: content,
            location: location,
            highlightColor: color
        )
    }

    static func skipBlankLines(in lines: [String], index: inout Int) {
        while index < lines.count,
              normalizeWhitespace(lines[index]).isEmpty {
            index += 1
        }
    }

    static func normalizeWhitespace(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
