//
//  Favorites.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @EnvironmentObject private var coordinator: FavoritesCoordinator

    @ObservedObject var viewModel: FavoritesViewModel
    @State private var isCreateListPresented = false

    var body: some View {
        Group {
            if viewModel.lists.isEmpty {
                FavoritesEmptyState(
                    title: Localization.string("favorites.empty.title"),
                    message: Localization.string(sessionManager.isSignedIn ? "favorites.empty.signedIn" : "favorites.empty.signedOut"),
                    actionTitle: Localization.string("favorites.create.title")
                ) {
                    isCreateListPresented = true
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        FavoritesSummaryCard(
                            listCount: viewModel.lists.count,
                            movieCount: viewModel.totalMovieCount
                        )

                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.lists) { list in
                                FavoriteListRow(
                                    list: list,
                                    openList: { coordinator.show(.list(list.id)) }
                                )
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(AppPalette.screenBackground)
                .animation(.easeInOut(duration: 0.22), value: viewModel.lists.map(\.id))
            }
        }
        .navigationTitle(Localization.string("favorites.title"))
        .background(AppPalette.screenBackground)
        .animation(AppAnimation.standard, value: viewModel.lists.isEmpty)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreateListPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Localization.string("favorites.create.title"))
                .accessibilityIdentifier("favorites.create.button")
            }
        }
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                NewFavoriteListView(movie: nil)
            }
        }
    }
}
