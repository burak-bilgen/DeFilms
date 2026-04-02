//
//  Localization.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

enum Localization {
    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        let languageCode = AppPreferences.persistedLanguage.rawValue
        let bundle = bundle(for: languageCode)
        let format = NSLocalizedString(key, bundle: bundle, comment: "")
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: languageCode), arguments: arguments)
    }

    static func bundle(for languageCode: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
