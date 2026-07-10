//
//  SettingsView.swift
//  Quotations
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ExploreSettingsPane()
                .tabItem {
                    Label("Explore", systemImage: "chart.dots.scatter")
                }
        }
        .frame(minWidth: 420, minHeight: 480)
    }
}

#Preview {
    SettingsView()
        .environment(StopWordsStore(userDefaults: UserDefaults(suiteName: "SettingsPreview")!))
}
