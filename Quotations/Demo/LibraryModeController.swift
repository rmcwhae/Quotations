//
//  LibraryModeController.swift
//  Quotations
//

import Foundation
import Observation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class LibraryModeController {
    static let userDefaultsKey = "demoModeEnabled"

    /// Synchronous flag for side-effect gates outside the view tree (e.g. `saveAndNotify`).
    private(set) static var isDemoModeActive = false

    private(set) var isDemoMode: Bool
    private(set) var activeContainer: ModelContainer

    private let personalContainer: ModelContainer
    private let userDefaults: UserDefaults
    private let schema: Schema

    var isDemoModeBinding: Binding<Bool> {
        Binding(
            get: { self.isDemoMode },
            set: { self.setDemoMode($0) }
        )
    }

    var windowTitle: String {
        isDemoMode ? "Quotations (Demo)" : "Quotations"
    }

    init(
        personalContainer: ModelContainer,
        userDefaults: UserDefaults = .standard,
        schema: Schema = Schema([Author.self, Source.self, Quotation.self])
    ) {
        self.personalContainer = personalContainer
        self.userDefaults = userDefaults
        self.schema = schema

        let storedDemoMode = userDefaults.bool(forKey: Self.userDefaultsKey)
        if storedDemoMode, let demoContainer = try? DemoLibrarySeeder.makeContainer(schema: schema) {
            isDemoMode = true
            activeContainer = demoContainer
            Self.isDemoModeActive = true
        } else {
            isDemoMode = false
            activeContainer = personalContainer
            Self.isDemoModeActive = false
            if storedDemoMode {
                userDefaults.set(false, forKey: Self.userDefaultsKey)
            }
        }
    }

    func setDemoMode(_ enabled: Bool) {
        guard enabled != isDemoMode else { return }

        if enabled {
            do {
                let demoContainer = try DemoLibrarySeeder.makeContainer(schema: schema)
                activeContainer = demoContainer
                isDemoMode = true
                Self.isDemoModeActive = true
                userDefaults.set(true, forKey: Self.userDefaultsKey)
                NotificationCenter.default.post(name: .demoModeDidChange, object: nil)
            } catch {
                // Keep personal library if demo seeding fails.
                isDemoMode = false
                Self.isDemoModeActive = false
                activeContainer = personalContainer
                userDefaults.set(false, forKey: Self.userDefaultsKey)
            }
        } else {
            isDemoMode = false
            Self.isDemoModeActive = false
            activeContainer = personalContainer
            userDefaults.set(false, forKey: Self.userDefaultsKey)
            NotificationCenter.default.post(name: .demoModeDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let demoModeDidChange = Notification.Name("demoModeDidChange")
}
