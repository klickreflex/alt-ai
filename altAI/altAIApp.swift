//
//  altAIApp.swift
//  altAI
//
//  Created by Daniel Wentsch on 11.11.24.
//

import SwiftUI

@main
struct altAIApp: App {
    var body: some Scene {
        WindowGroup {
            ImageGridView()
        }

        Settings {
            SettingsView()
        }
    }
}
