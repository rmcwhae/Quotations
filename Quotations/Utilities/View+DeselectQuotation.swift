//
//  View+DeselectQuotation.swift
//  Quotations
//

import SwiftData
import SwiftUI

extension View {
    /// Clears quotation selection when the user clicks empty space in the detail pane.
    func deselectQuotationOnBackgroundTap(_ selectedQuotationId: Binding<PersistentIdentifier?>) -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedQuotationId.wrappedValue = nil
                }
        }
    }
}
