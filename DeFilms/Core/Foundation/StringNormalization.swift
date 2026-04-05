//
//  StringNormalization.swift
//  DeFilms
//

import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedForLookup: String {
        trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
