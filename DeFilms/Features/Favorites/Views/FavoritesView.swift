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
    @State private var listPendingRename: FavoriteList?
    @State private var renameText: String = ""
    @State private var listPendingDeletion: FavoriteList?

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
                                    openList: { coordinator.show(.list(list.id)) },
                                    renameList: {
                                        listPendingRename = list
                                        renameText = list.name
                                    },
                                    deleteList: {
                                        listPendingDeletion = list
                                    }
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
        .alert(
            Localization.string("favorites.rename.title"),
            isPresented: Binding(
                get: { listPendingRename != nil },
                set: { isPresented in
                    if !isPresented {
                        listPendingRename = nil
                    }
                }
            )
        ) {
            TextField(Localization.string("favorites.picker.placeholder"), text: $renameText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button(Localization.string("common.cancel"), role: .cancel) {
                listPendingRename = nil
            }
            Button(Localization.string("favorites.rename.confirm")) {
                guard let listPendingRename else { return }
                if viewModel.renameList(listID: listPendingRename.id, name: renameText) {
                    self.listPendingRename = nil
                }
            }
        }
        .confirmationDialog(
            Localization.string("favorites.delete.title"),
            isPresented: Binding(
                get: { listPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        listPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(Localization.string("favorites.delete.confirm"), role: .destructive) {
                if let listPendingDeletion {
                    viewModel.deleteList(listID: listPendingDeletion.id)
                    self.listPendingDeletion = nil
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {
                listPendingDeletion = nil
            }
        } message: {
            Text(Localization.string("favorites.delete.message", listPendingDeletion?.name ?? ""))
        }
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                NewFavoriteListView(movie: nil)
            }
        }
    }
}
