//
//  ContentViewShellState.swift
//  Quotations
//

import SwiftData
import SwiftUI

struct ContentViewShellState {
    var navigation: LibraryNavigationState
    var findInPage: FindInPageState
    var exploreState: ExploreState
    var chatState: ChatState
    var selectedSourceId: Binding<PersistentIdentifier?>
    var selectedQuotationId: Binding<PersistentIdentifier?>
    var findQuery: Binding<String>
}
