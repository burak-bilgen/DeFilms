
import SwiftUI

struct MovieListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: ListsCoordinator

    @ObservedObject var viewModel: MovieListDetailViewModel
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    @State private var renameText: String = ""
    @State private var isRenamePresented = false
    @State private var isDeletePresented = false
    @State private var isListActionsPresented = false
    @State private var isSharePreviewPresented = false
    @State private var moviePendingManagement: ListedMovie?

    var body: some View {
        Group {
            if let list = viewModel.list {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        MovieListDetailHeader(list: list)
                            .padding(.horizontal, 16)

                        if list.movies.isEmpty {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                    .frame(maxHeight: 70)

                                MovieListDetailEmptyState(listName: list.name)
                                    .padding(.horizontal, 16)

                                Spacer(minLength: 0)
                                    .layoutPriority(1)
                            }
                            .frame(maxWidth: .infinity, minHeight: 420)
                        } else {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(list.movies) { movie in
                                    ListedMovieGridItem(
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
                    if viewModel.shareText != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isSharePreviewPresented = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel(Localization.string("lists.share.button"))
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
                    title: Localization.string("lists.list.unavailable.title"),
                    message: Localization.string("lists.list.unavailable.message"),
                    buttonTitle: nil,
                    action: nil
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .confirmationDialog(
            Localization.string("lists.manage.movie"),
            isPresented: $isListActionsPresented,
            titleVisibility: .hidden
        ) {
            if let list = viewModel.list {
                Button(Localization.string("lists.rename.title")) {
                    renameText = list.name
                    isRenamePresented = true
                }

                Button(Localization.string("lists.delete.confirm"), role: .destructive) {
                    isDeletePresented = true
                }
            }

            Button(Localization.string("common.cancel"), role: .cancel) {}
        }
        .alert(Localization.string("lists.rename.title"), isPresented: $isRenamePresented) {
            TextField(Localization.string("lists.picker.placeholder"), text: $renameText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button(Localization.string("common.cancel"), role: .cancel) {}
            Button(Localization.string("lists.rename.confirm")) {
                Task {
                    _ = await viewModel.renameList(name: renameText)
                }
            }
        }
        .alert(Localization.string("lists.delete.title"), isPresented: $isDeletePresented) {
            Button(Localization.string("lists.delete.confirm"), role: .destructive) {
                Task {
                    await viewModel.deleteList()
                    dismiss()
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(Localization.string("lists.delete.message", viewModel.list?.name ?? ""))
        }
        .fullScreenCover(item: $moviePendingManagement, onDismiss: {
            moviePendingManagement = nil
        }) { movie in
            ListedMovieManagementModalView(
                movie: movie,
                destinations: viewModel.destinationOptions(for: movie.id),
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
        .sheet(isPresented: $isSharePreviewPresented) {
            if let list = viewModel.list, let shareText = viewModel.shareText {
                MovieListSharePreview(list: list, shareText: shareText)
            }
        }
    }
}

private struct MovieListSharePreview: View {
    let list: MovieList
    let shareText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    MovieListShareCard(list: list)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)

                    ShareLink(item: shareText) {
                        Label(Localization.string("lists.share.button"), systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryProminentButtonStyle())
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppPalette.screenBackground)
            .navigationTitle(Localization.string("lists.share.preview.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Localization.string("common.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MovieListShareCard: View {
    let list: MovieList

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("DeFilms")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                Text(list.name)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(Localization.string("lists.list.card.subtitle", list.movies.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                ForEach(Array(list.movies.prefix(6))) { movie in
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        PosterImageView(
                            url: movie.asMovie.posterURL,
                            cornerRadius: 12,
                            placeholderSystemImage: "film"
                        )
                        .aspectRatio(AppDimension.posterAspectRatio, contentMode: .fit)

                        Text(movie.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [AppPalette.cardBackground, AppPalette.cardAccentBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous))
        .shadow(color: AppPalette.shadow.opacity(0.8), radius: 16, x: 0, y: 10)
    }
}

private struct ListedMovieGridItem: View {
    let movie: ListedMovie
    let openMovie: () -> Void
    let manageMovie: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: openMovie) {
                MovieCardView(
                    movie: movie.asMovie,
                    titleFont: .footnote,
                    contentSpacing: AppSpacing.xs,
                    metadataSpacing: 2,
                    posterCornerRadius: 14,
                    showsListButton: false
                )
                .padding(.horizontal, 3)
            }
            .buttonStyle(.plain)

            Button(action: manageMovie) {
                Image(systemName: "ellipsis")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.elevatedBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppPalette.border, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                    .padding(.top, 10)
                    .padding(.trailing, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.string("lists.manage.movie"))
        }
    }
}

private struct MovieListDetailHeader: View {
    let list: MovieList

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(list.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(Localization.string("lists.list.detail.subtitle", list.movies.count))
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

private struct MovieListDetailEmptyState: View {
    let listName: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Localization.string("lists.list.empty.title"))
                .font(.headline.weight(.bold))

            Text(Localization.string("lists.list.empty.message", listName))
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
