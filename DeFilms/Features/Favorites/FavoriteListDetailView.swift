//
//  FavoriteListDetailView.swift
//  DeFilms
//

import SwiftUI

struct FavoriteListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: NavigationCoordinator<FavoritesRoute>

    @ObservedObject var viewModel: FavoriteListDetailViewModel
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    @State private var renameText: String = ""
    @State private var isRenamePresented = false
    @State private var isDeletePresented = false
    @State private var moviePendingRemoval: FavoriteMovie?
    @State private var moviePendingMove: FavoriteMovie?
    @State private var isCreateListForMovePresented = false

    var body: some View {
        Group {
            if let list = viewModel.list {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        FavoriteListDetailHeader(list: list)
                            .padding(.horizontal, 16)

                        if list.movies.isEmpty {
                            FavoriteListDetailEmptyState(listName: list.name)
                                .padding(.horizontal, 16)
                        } else {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(list.movies) { movie in
                                    FavoriteMovieGridItem(
                                        movie: movie,
                                        openMovie: { coordinator.push(.movie(movie.asMovie)) },
                                        moveMovie: { moviePendingMove = movie },
                                        removeMovie: { moviePendingRemoval = movie }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(list.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(Localization.string("favorites.rename.title")) {
                                renameText = list.name
                                isRenamePresented = true
                            }

                            Button(Localization.string("favorites.delete.confirm"), role: .destructive) {
                                isDeletePresented = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            } else {
                MoviesMessageView(
                    title: Localization.string("favorites.list.unavailable.title"),
                    message: Localization.string("favorites.list.unavailable.message"),
                    buttonTitle: nil,
                    action: nil
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    dismiss()
                }
            }
        }
        .alert(Localization.string("favorites.rename.title"), isPresented: $isRenamePresented) {
            TextField(Localization.string("favorites.picker.placeholder"), text: $renameText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button(Localization.string("common.cancel"), role: .cancel) {}
            Button(Localization.string("favorites.rename.confirm")) {
                _ = viewModel.renameList(name: renameText)
            }
        }
        .confirmationDialog(Localization.string("favorites.delete.title"), isPresented: $isDeletePresented, titleVisibility: .visible) {
            Button(Localization.string("favorites.delete.confirm"), role: .destructive) {
                viewModel.deleteList()
                dismiss()
            }
            Button(Localization.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(Localization.string("favorites.delete.message", viewModel.list?.name ?? ""))
        }
        .confirmationDialog(
            Localization.string("favorites.remove.movie.title"),
            isPresented: Binding(
                get: { moviePendingRemoval != nil },
                set: { isPresented in
                    if !isPresented {
                        moviePendingRemoval = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(Localization.string("favorites.remove.movie.confirm"), role: .destructive) {
                if let moviePendingRemoval {
                    viewModel.remove(movieID: moviePendingRemoval.id)
                    self.moviePendingRemoval = nil
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {
                moviePendingRemoval = nil
            }
        } message: {
            Text(Localization.string("favorites.remove.movie.message", moviePendingRemoval?.title ?? ""))
        }
        .confirmationDialog(
            Localization.string("favorites.move.title"),
            isPresented: Binding(
                get: { moviePendingMove != nil },
                set: { isPresented in
                    if !isPresented {
                        moviePendingMove = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if viewModel.destinationLists.isEmpty {
                Button(Localization.string("favorites.create.title")) {
                    isCreateListForMovePresented = true
                }
            } else {
                ForEach(viewModel.destinationLists) { destination in
                    Button(destination.name) {
                        if let moviePendingMove {
                            viewModel.move(movieID: moviePendingMove.id, to: destination.id)
                            self.moviePendingMove = nil
                        }
                    }
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {
                moviePendingMove = nil
            }
        } message: {
            Text(
                viewModel.destinationLists.isEmpty
                    ? Localization.string("favorites.create.subtitle.movie")
                    : Localization.string("favorites.move.message", moviePendingMove?.title ?? "")
            )
        }
        .sheet(isPresented: $isCreateListForMovePresented, onDismiss: {
            moviePendingMove = nil
        }) {
            if let moviePendingMove {
                NavigationStack {
                    NewFavoriteListView(movie: moviePendingMove.asMovie) { _ in
                        viewModel.remove(movieID: moviePendingMove.id)
                    }
                }
            }
        }
    }
}

private struct FavoriteMovieGridItem: View {
    let movie: FavoriteMovie
    let openMovie: () -> Void
    let moveMovie: () -> Void
    let removeMovie: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Button(action: openMovie) {
                MovieCardView(movie: movie.asMovie)
            }
            .buttonStyle(.plain)

            Menu {
                Button(Localization.string("favorites.move.title"), action: moveMovie)
                Button(Localization.string("favorites.remove.movie.confirm"), role: .destructive, action: removeMovie)
            } label: {
                Label(Localization.string("favorites.manage.movie"), systemImage: "ellipsis.circle")
                    .font(.caption.weight(.semibold))
            }
            .tint(.primary)
        }
    }
}

private struct FavoriteListDetailHeader: View {
    let list: FavoriteList

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(list.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(Localization.string("favorites.list.detail.subtitle", list.movies.count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct FavoriteListDetailEmptyState: View {
    let listName: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(Localization.string("favorites.list.empty.title"))
                .font(.headline.weight(.bold))

            Text(Localization.string("favorites.list.empty.message", listName))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 22)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
