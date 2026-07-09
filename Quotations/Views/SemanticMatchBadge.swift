//
//  SemanticMatchBadge.swift
//  Quotations
//

import SwiftUI

struct SemanticMatchBadge: View {
    var body: some View {
        Label("Concept match", systemImage: "sparkles")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.tertiary)
            .labelStyle(.titleAndIcon)
            .accessibilityLabel("Concept match from semantic search")
    }
}
