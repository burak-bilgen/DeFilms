//
//  SearchHistoryView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct SearchHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !history.isEmpty {
                Text(Localization.string("movies.recentSearches"))
                    .font(.headline)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(history, id: \.self) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                Text(item)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
