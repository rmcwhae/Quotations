//
//  View+DeselectQuotation.swift
//  Quotations
//

import SwiftData
import SwiftUI

extension View {
    /// Clears quotation selection when the user clicks empty space or presses Escape.
    func deselectQuotationOnBackgroundTap(_ selectedQuotationId: Binding<PersistentIdentifier?>) -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedQuotationId.wrappedValue = nil
                }
        }
        .onKeyPress(.escape) {
            guard selectedQuotationId.wrappedValue != nil else { return .ignored }
            selectedQuotationId.wrappedValue = nil
            return .handled
        }
    }
}
