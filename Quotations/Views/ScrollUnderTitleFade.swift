//
//  ScrollUnderTitleFade.swift
//  Quotations
//

import SwiftUI

/// Fixed gradient at the top of a scroll view so list content fades under the navigation title.
struct ScrollUnderTitleFadeOverlay: View {
    var height: CGFloat = LayoutMetrics.scrollUnderTitleFadeHeight
    var background: Color = Color(nsColor: .windowBackgroundColor)

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: background, location: 0),
                .init(color: background.opacity(0.92), location: 0.45),
                .init(color: background.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Overlays a top fade so scrolled content dissolves beneath the column title.
    func scrollUnderTitleFade(
        height: CGFloat = LayoutMetrics.scrollUnderTitleFadeHeight,
        background: Color = Color(nsColor: .windowBackgroundColor)
    ) -> some View {
        overlay(alignment: .top) {
            ScrollUnderTitleFadeOverlay(height: height, background: background)
                .ignoresSafeArea(.container, edges: .top)
        }
    }
}
