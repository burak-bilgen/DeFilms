
import Foundation

enum Localization {
    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        let language = AppPreferences.persistedLanguage
        let bundle = bundle(for: language)
        let format = NSLocalizedString(key, bundle: bundle, comment: "")
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: language.locale, arguments: arguments)
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
