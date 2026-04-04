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
    let onClear: () -> Void
    @State private var isClearConfirmationPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !history.isEmpty {
                HStack(spacing: 12) {
                    Text(Localization.string("movies.recentSearches"))
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button {
                        isClearConfirmationPresented = true
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 30, height: 30)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Localization.string("movies.searchHistory.clear"))
                }
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
                            .accessibilityLabel(Localization.string("movies.accessibility.recentSearch", item))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: history)
        .confirmationDialog(
            Localization.string("movies.searchHistory.clear.confirmTitle"),
            isPresented: $isClearConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(Localization.string("movies.searchHistory.clear.confirmAction"), role: .destructive) {
                withAnimation(.easeInOut(duration: 0.22)) {
                    onClear()
                }
            }

            Button(Localization.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(Localization.string("movies.searchHistory.clear.confirmMessage"))
        }
    }
}
