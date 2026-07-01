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
        var records: [[String]] = []
        var currentRecord: [String] = []
        var currentFieldBytes: [UInt8] = []
        var insideQuotes = false
        var index = 0

        func decodeField() -> String {
            String(decoding: currentFieldBytes, as: UTF8.self)
        }

        func finishField() {
            currentRecord.append(decodeField())
            currentFieldBytes.removeAll(keepingCapacity: true)
        }

        func finishRecord() {
            finishField()
            records.append(currentRecord)
            currentRecord = []
        }

        while index < bytes.count {
            let byte = bytes[index]

            if insideQuotes {
                if byte == 0x22 {
                    let next = index + 1
                    if next < bytes.count, bytes[next] == 0x22 {
                        currentFieldBytes.append(0x22)
                        index = next + 1
                        continue
                    }
                    insideQuotes = false
                } else {
                    currentFieldBytes.append(byte)
                }
            } else {
                switch byte {
                case 0x22:
                    insideQuotes = true
                case 0x2C:
                    finishField()
                case 0x0A:
                    finishRecord()
                case 0x0D:
                    if index + 1 < bytes.count, bytes[index + 1] == 0x0A {
                        index += 1
                    }
                    finishRecord()
                default:
                    currentFieldBytes.append(byte)
                }
            }

            index += 1
        }

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
