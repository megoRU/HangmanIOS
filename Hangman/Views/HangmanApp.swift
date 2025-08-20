//
//  HangmanApp.swift
//  Hangman
//
//  Created by mego on 30.07.2025.
//

import SwiftUI
import UserNotifications

@main
struct HangmanApp: App {
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue

    init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Разрешение на уведомления получено.")
            } else if let error = error {
                print("Ошибка разрешения на уведомления: \(error.localizedDescription)")
            }
        }
    }

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
                .preferredColorScheme(preferredScheme)
        }
    }
}
