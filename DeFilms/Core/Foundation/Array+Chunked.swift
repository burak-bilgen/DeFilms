//
//  Array+Chunked.swift
//  DeFilms
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }

        var chunks: [[Element]] = []
        var startIndex = startIndex

        while startIndex < endIndex {
            let endIndex = index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            chunks.append(Array(self[startIndex..<endIndex]))
            startIndex = endIndex
        }

        return chunks
    }
}
