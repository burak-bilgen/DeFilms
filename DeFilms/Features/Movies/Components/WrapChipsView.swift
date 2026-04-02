//
//  WrapChipsView.swift
//  DeFilms
//

import SwiftUI

struct WrapChipsView: View {
    let items: [String]
    var inverted: Bool = false

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 8) {
                ForEach(items.prefix(3), id: \.self) { item in
                    chip(item)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(Array(items.prefix(4)).chunked(into: 2).enumerated()), id: \.offset) { entry in
                    HStack(spacing: 8) {
                        ForEach(entry.element, id: \.self) { item in
                            chip(item)
                        }
                    }
                }
            }
        }
    }

    private func chip(_ item: String) -> some View {
        Text(item)
            .font(.caption.weight(.medium))
            .foregroundStyle(inverted ? .white.opacity(0.92) : .secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(inverted ? Color.white.opacity(0.16) : Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }

        var result: [[Element]] = []
        var index = startIndex

        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[index..<end]))
            index = end
        }

        return result
    }
}
