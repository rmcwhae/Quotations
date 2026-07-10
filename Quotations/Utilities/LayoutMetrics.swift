//
//  LayoutMetrics.swift
//  Quotations
//

import CoreGraphics

enum LayoutMetrics {
    /// Minimum width of the detail (third) column in the navigation split view.
    static let detailColumnMinWidth: CGFloat = 380
    /// Extra leading inset for the content (second) column so the sidebar shadow
    /// does not obscure list and page content.
    static let contentColumnLeadingPadding: CGFloat = 12
    /// Natural width of a quotation row column (centered in the detail pane).
    static let quotationColumnMaxWidth: CGFloat = 616
    static let quotationListTopPadding: CGFloat = 4
    static let quotationListBottomPadding: CGFloat = 16
    /// Height of the top fade when list content scrolls under a navigation title.
    static let scrollUnderTitleFadeHeight: CGFloat = 72
}
