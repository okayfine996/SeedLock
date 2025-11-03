//
//  LanguageManager.swift
//  seedlock
//
//  Created by Fine Ke on 26/10/2025.
//

import Foundation
import SwiftUI

/// Manages app language settings and localization
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            saveLanguagePreference()
            updateAppLanguage()
        }
    }
    
    enum Language: String, CaseIterable {
        case english = "en"
        case chinese = "zh-Hans"
        
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            }
        }
        
        var nativeName: String {
            switch self {
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            }
        }
    }
    
    private init() {
        // Load saved language preference or use system language
        if let savedLanguageCode = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = Language(rawValue: savedLanguageCode) {
            self.currentLanguage = language
        } else {
            // Detect system language
            let systemLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
            if systemLanguageCode.starts(with: "zh") {
                self.currentLanguage = .chinese
            } else {
                self.currentLanguage = .english
            }
        }
    }
    
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
    }
    
    private func updateAppLanguage() {
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Notify the app to refresh
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
    
    /// Get localized string for the current language
    func localizedString(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    /// Get Locale for the current language
    var currentLocale: Locale {
        return Locale(identifier: currentLanguage.rawValue)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - String Extension for Localization

extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
    
    func localized(_ args: CVarArg...) -> String {
        return String(format: localized, arguments: args)
    }
}

// MARK: - Environment Key for Language

private struct LanguageKey: EnvironmentKey {
    static let defaultValue: LanguageManager.Language = .english
}

extension EnvironmentValues {
    var appLanguage: LanguageManager.Language {
        get { self[LanguageKey.self] }
        set { self[LanguageKey.self] = newValue }
    }
}

