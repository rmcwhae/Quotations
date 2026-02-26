//
//  SidebarMaterialBackground.swift
//  Quotations
//
//  Finder-style translucent sidebar material for the full window, including title bar area.
//

#if os(macOS)
import AppKit
import SwiftUI

// MARK: - Transparent window (so vibrancy can show the desktop)

struct TransparentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(WindowConfigurator())
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        v.wantsLayer = true
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        // Hide title text; apply asynchronously so it persists after SwiftUI sets the window title.
        DispatchQueue.main.async {
            window.titleVisibility = .hidden
        }
    }
}

// MARK: - Sidebar material (same as Finder sidebar)

struct SidebarMaterialView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effect = NSVisualEffectView()
        effect.material = .sidebar
        effect.blendingMode = .behindWindow
        effect.state = .active
        return effect
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif
