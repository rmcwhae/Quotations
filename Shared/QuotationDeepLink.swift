//
//  QuotationDeepLink.swift
//  Quotations
//

import Foundation
import SwiftData

enum QuotationDeepLink {
    static let scheme = "quotations"

    enum Route: Equatable {
        case home
        case quotation(PersistentIdentifier, sourceID: PersistentIdentifier?)
    }

    struct URLParameters: Equatable {
        let encodedQuotationID: String
        let encodedSourceID: String?
    }

    static func url(for route: Route) -> URL? {
        switch route {
        case .home:
            return URL(string: "\(scheme)://open")
        case .quotation(let quotationID, let sourceID):
            guard let encodedQuotationID = encode(quotationID) else { return nil }
            var components = URLComponents()
            components.scheme = scheme
            components.host = "open"
            components.path = "/quotation"
            var queryItems = [URLQueryItem(name: "id", value: encodedQuotationID)]
            if let sourceID, let encodedSourceID = encode(sourceID) {
                queryItems.append(URLQueryItem(name: "source", value: encodedSourceID))
            }
            components.queryItems = queryItems
            return components.url
        }
    }

    static func parse(_ url: URL) -> Route? {
        guard url.scheme?.lowercased() == scheme else { return nil }

        let host = url.host?.lowercased()
        let path = url.path.lowercased()
        guard host == "quotation" || path == "/quotation" || host == "open" && path == "/quotation" else {
            return .home
        }

        guard let parameters = parseURLParameters(url),
              let quotationID = resolvePersistentIdentifier(fromEncodedToken: parameters.encodedQuotationID) else {
            return nil
        }

        let sourceID = parameters.encodedSourceID.flatMap(resolvePersistentIdentifier(fromEncodedToken:))
        return .quotation(quotationID, sourceID: sourceID)
    }

    static func parseIncomingURL(_ url: URL) -> Route? {
        guard url.scheme?.lowercased() == scheme else { return nil }

        if let parameters = parseURLParameters(url),
           let quotationID = resolvePersistentIdentifier(fromEncodedToken: parameters.encodedQuotationID) {
            let sourceID = parameters.encodedSourceID.flatMap(resolvePersistentIdentifier(fromEncodedToken:))
            return .quotation(quotationID, sourceID: sourceID)
        }

        return parse(url) ?? .home
    }

    static func parseURLParameters(_ url: URL) -> URLParameters? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idValue = components.queryItems?.first(where: { $0.name == "id" })?.value,
              !idValue.isEmpty else {
            return nil
        }

        let sourceValue = components.queryItems?
            .first(where: { $0.name == "source" })?
            .value

        return URLParameters(
            encodedQuotationID: idValue,
            encodedSourceID: sourceValue?.isEmpty == false ? sourceValue : nil
        )
    }

    /// Stable across processes: encodes the Core Data URI, not the full JSON PersistentIdentifier.
    static func encode(_ id: PersistentIdentifier) -> String? {
        guard let uri = uriRepresentation(for: id) else { return nil }
        return base64URLEncode(Data(uri.utf8))
    }

    static func decode(_ string: String) -> PersistentIdentifier? {
        resolvePersistentIdentifier(fromEncodedToken: string)
    }

    static func persistentIdentifiersMatch(
        encodedToken: String,
        modelID: PersistentIdentifier
    ) -> Bool {
        guard let targetURI = entityURI(fromEncodedToken: encodedToken),
              let modelURI = uriRepresentation(for: modelID) else {
            return false
        }
        return targetURI == modelURI
    }

    static func resolvePersistentIdentifier(fromEncodedToken token: String) -> PersistentIdentifier? {
        guard let data = base64URLDecode(token) else { return nil }

        if let uri = String(data: data, encoding: .utf8), uri.hasPrefix("x-coredata://") {
            return persistentIdentifier(forURI: uri)
        }

        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }

    static func uriRepresentation(for id: PersistentIdentifier) -> String? {
        guard let data = try? JSONEncoder().encode(id),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let implementation = json["implementation"] as? [String: Any],
              let uri = implementation["uriRepresentation"] as? String else {
            return nil
        }
        return uri
    }

    static func entityURI(fromEncodedToken token: String) -> String? {
        guard let data = base64URLDecode(token) else { return nil }

        if let uri = String(data: data, encoding: .utf8), uri.hasPrefix("x-coredata://") {
            return uri
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let implementation = json["implementation"] as? [String: Any],
              let uri = implementation["uriRepresentation"] as? String else {
            return nil
        }
        return uri
    }

    private static func persistentIdentifier(forURI uri: String) -> PersistentIdentifier? {
        guard let uriData = uri.data(using: .utf8),
              let primaryKey = uri.split(separator: "/").last.map(String.init) else {
            return nil
        }

        let entityName: String
        let components = uri.split(separator: "/")
        if components.count >= 2 {
            entityName = String(components[components.count - 2])
        } else {
            return nil
        }

        let storeIdentifier = uri
            .replacingOccurrences(of: "x-coredata://", with: "")
            .split(separator: "/")
            .first
            .map(String.init)

        let payload: [String: Any] = [
            "implementation": [
                "entityName": entityName,
                "uriRepresentation": uri,
                "isTemporary": false,
                "primaryKey": primaryKey,
                "storeIdentifier": storeIdentifier as Any
            ]
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload) else {
            return nil
        }

        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: padding)
        return Data(base64Encoded: base64)
    }
}
