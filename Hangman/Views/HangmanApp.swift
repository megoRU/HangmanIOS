//
//  HangmanApp.swift
//  Hangman
//
//  Created by mego on 30.07.2025.
//

import SwiftUI

@main
struct HangmanApp: App {
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue

    var preferredScheme: ColorScheme? {
        if let theme = AppTheme(rawValue: selectedTheme) {
            switch theme {
            case .light: return .light
            case .dark: return .dark
            default: return nil
            }
        }
        return nil
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(StatsManager.shared)
                .preferredColorScheme(preferredScheme)
        }
    }
}
