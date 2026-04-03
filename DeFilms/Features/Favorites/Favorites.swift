//
//  Favorites.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @EnvironmentObject private var coordinator: NavigationCoordinator<FavoritesRoute>

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
                                    openList: { coordinator.push(.list(list.id)) },
                                    renameList: {
                                        listPendingRename = list
                                        renameText = list.name
                                    },
                                    deleteList: {
                                        listPendingDeletion = list
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(Localization.string("favorites.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreateListPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Localization.string("favorites.create.title"))
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

private struct FavoriteListRow: View {
    let list: FavoriteList
    let openList: () -> Void
    let renameList: () -> Void
    let deleteList: () -> Void

    var body: some View {
        Button(action: openList) {
            FavoriteListCard(list: list)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(Localization.string("favorites.rename.title"), action: renameList)
            Button(Localization.string("favorites.delete.confirm"), role: .destructive, action: deleteList)
        }
    }
}

private struct FavoritesEmptyState: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.weight(.bold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button(actionTitle, action: action)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.systemBackground))
                .frame(height: 50)
                .padding(.horizontal, 22)
                .background(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct FavoritesSummaryCard: View {
    let listCount: Int
    let movieCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("favorites.summary.title"))
                .font(.title2.weight(.bold))

            Text(Localization.string("favorites.summary.subtitle", listCount, movieCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                summaryBadge(systemImage: "square.stack.3d.up.fill", text: Localization.string("favorites.summary.lists", listCount))
                summaryBadge(systemImage: "film.stack.fill", text: Localization.string("favorites.count", movieCount))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.tertiarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func summaryBadge(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Color.primary.opacity(0.07))
            .clipShape(Capsule())
    }
}

private struct FavoriteListCard: View {
    let list: FavoriteList

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(list.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(Localization.string("favorites.list.card.subtitle", list.movies.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            if list.movies.isEmpty {
                Text(Localization.string("favorites.list.empty.inline"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 10) {
                    ForEach(Array(list.movies.prefix(3))) { movie in
                        PosterImageView(
                            url: movie.asMovie.posterURL,
                            cornerRadius: 16,
                            placeholderSystemImage: "film"
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
