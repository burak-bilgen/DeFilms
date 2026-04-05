//
//  FavoriteListDetailView.swift
//  DeFilms
//

import SwiftUI

struct FavoriteListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: FavoritesCoordinator

    @ObservedObject var viewModel: FavoriteListDetailViewModel
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    @State private var renameText: String = ""
    @State private var isRenamePresented = false
    @State private var isDeletePresented = false
    @State private var isListActionsPresented = false
    @State private var moviePendingManagement: FavoriteMovie?

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
                                        openMovie: { coordinator.show(.movie(movie.asMovie)) },
                                        manageMovie: { moviePendingManagement = movie }
                                    )
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                }
                            }
                            .padding(.horizontal, 16)
                            .animation(.easeInOut(duration: 0.24), value: list.movies.map(\.id))
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(list.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if let shareText = viewModel.shareText {
                        ToolbarItem(placement: .topBarTrailing) {
                            ShareLink(item: shareText) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel(Localization.string("favorites.share.button"))
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isListActionsPresented = true
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
            }
        }
        .confirmationDialog(
            Localization.string("favorites.manage.movie"),
            isPresented: $isListActionsPresented,
            titleVisibility: .hidden
        ) {
            if let list = viewModel.list {
                Button(Localization.string("favorites.rename.title")) {
                    renameText = list.name
                    isRenamePresented = true
                }

                Button(Localization.string("favorites.delete.confirm"), role: .destructive) {
                    isDeletePresented = true
                }
            }

            Button(Localization.string("common.cancel"), role: .cancel) {}
        }
        .alert(Localization.string("favorites.rename.title"), isPresented: $isRenamePresented) {
            TextField(Localization.string("favorites.picker.placeholder"), text: $renameText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button(Localization.string("common.cancel"), role: .cancel) {}
            Button(Localization.string("favorites.rename.confirm")) {
                Task {
                    _ = await viewModel.renameList(name: renameText)
                }
            }
        }
        .alert(Localization.string("favorites.delete.title"), isPresented: $isDeletePresented) {
            Button(Localization.string("favorites.delete.confirm"), role: .destructive) {
                Task {
                    await viewModel.deleteList()
                    dismiss()
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(Localization.string("favorites.delete.message", viewModel.list?.name ?? ""))
        }
        .fullScreenCover(item: $moviePendingManagement, onDismiss: {
            moviePendingManagement = nil
        }) { movie in
            FavoriteMovieManagementModalView(
                movie: movie,
                destinationLists: viewModel.destinationLists,
                moveMovie: { destinationID in
                    Task {
                        await viewModel.move(movieID: movie.id, to: destinationID)
                    }
                },
                createListAndMove: { listName in
                    await viewModel.createDestinationListAndMove(movieID: movie.id, listName: listName)
                },
                removeMovie: {
                    Task {
                        await viewModel.remove(movieID: movie.id)
                    }
                }
            )
        }
    }
}

private struct FavoriteMovieGridItem: View {
    let movie: FavoriteMovie
    let openMovie: () -> Void
    let manageMovie: () -> Void

    var body: some View {
        Button(action: openMovie) {
            MovieCardView(
                movie: movie.asMovie,
                titleFont: .footnote,
                contentSpacing: AppSpacing.xs,
                metadataSpacing: 2,
                posterCornerRadius: 14,
                showsFavoriteButton: false
            )
            .padding(.horizontal, 3)
            .overlay(alignment: .topTrailing) {
                Button(action: manageMovie) {
                    Image(systemName: "ellipsis")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.96))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                        .padding(.top, 10)
                        .padding(.trailing, 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.string("favorites.manage.movie"))
            }
        }
        .buttonStyle(.plain)
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
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Localization.string("favorites.list.empty.title"))
                .font(.headline.weight(.bold))

            Text(Localization.string("favorites.list.empty.message", listName))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg + 2)
        .appCardSurface()
        .accessibilityElement(children: .contain)
    }
}
