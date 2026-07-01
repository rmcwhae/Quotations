//
//  QuotationCSVParser.swift
//  Quotations
//

import Foundation

enum QuotationCSVParser {
    static func parse(data: Data) throws -> [QuotationCSVRow] {
        guard !data.isEmpty else {
            throw QuotationCSVImportError.emptyFile
        }

        var bytes = Array(data)
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) {
            bytes.removeFirst(3)
        }

        let records = try parseRecords(bytes)
        guard let headerRecord = records.first else {
            throw QuotationCSVImportError.emptyFile
        }

        let headers = headerRecord.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        guard let contentIndex = headers.firstIndex(of: "content") else {
            throw QuotationCSVImportError.invalidFormat("CSV must include a content column.")
        }

        let locationIndex = headers.firstIndex(of: "location")
        let sourceImageIndex = headers.firstIndex(of: "source_image")

        return records.dropFirst().map { fields in
            let content = value(at: contentIndex, in: fields)
            let location = locationIndex.flatMap { index in
                let value = value(at: index, in: fields)
                return value.isEmpty ? nil : value
            }
            let sourceImage = sourceImageIndex.flatMap { index in
                let value = value(at: index, in: fields)
                return value.isEmpty ? nil : value
            }
            return QuotationCSVRow(content: content, location: location, sourceImage: sourceImage)
        }
    }

    private static func value(at index: Int, in fields: [String]) -> String {
        guard index < fields.count else { return "" }
        return fields[index]
    }

    private static func parseRecords(_ bytes: [UInt8]) throws -> [[String]] {
        var builder = RecordBuilder()
        var index = 0

        while index < bytes.count {
            let byte = bytes[index]
            if builder.insideQuotes {
                index = builder.consumeQuoted(byte, bytes: bytes, at: index)
            } else {
                index = builder.consumeUnquoted(byte, bytes: bytes, at: index)
            }
        }

        return try builder.finish()
    }

    #if DEBUG
    static func debugRecordCount(data: Data) throws -> Int {
        guard !data.isEmpty else { return 0 }
        var bytes = Array(data)
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) {
            bytes.removeFirst(3)
        }
        return try parseRecords(bytes).count
    }
    #endif
}

private extension QuotationCSVParser {
    struct RecordBuilder {
        var records: [[String]] = []
        var currentRecord: [String] = []
        var currentFieldBytes: [UInt8] = []
        var insideQuotes = false

        mutating func consumeQuoted(_ byte: UInt8, bytes: [UInt8], at index: Int) -> Int {
            if byte == 0x22 {
                let next = index + 1
                if next < bytes.count, bytes[next] == 0x22 {
                    currentFieldBytes.append(0x22)
                    return next + 1
                }
                insideQuotes = false
            } else {
                currentFieldBytes.append(byte)
            }
            return index + 1
        }

        mutating func consumeUnquoted(_ byte: UInt8, bytes: [UInt8], at index: Int) -> Int {
            switch byte {
            case 0x22:
                insideQuotes = true
            case 0x2C:
                finishField()
            case 0x0A:
                finishRecord()
            case 0x0D:
                let nextIndex: Int
                if index + 1 < bytes.count, bytes[index + 1] == 0x0A {
                    nextIndex = index + 2
                } else {
                    nextIndex = index + 1
                }
                finishRecord()
                return nextIndex
            default:
                currentFieldBytes.append(byte)
            }
            return index + 1
        }

        mutating func finish() throws -> [[String]] {
            if insideQuotes {
                throw QuotationCSVImportError.invalidFormat("CSV contains an unclosed quoted field.")
            }
            if !currentFieldBytes.isEmpty || !currentRecord.isEmpty {
                finishRecord()
            }
            return records.filter { record in
                !record.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
        }

        private mutating func finishField() {
            let field = String(bytes: currentFieldBytes, encoding: .utf8) ?? ""
            currentRecord.append(field)
            currentFieldBytes.removeAll(keepingCapacity: true)
        }

        private mutating func finishRecord() {
            finishField()
            records.append(currentRecord)
            currentRecord = []
        }
    }
}
