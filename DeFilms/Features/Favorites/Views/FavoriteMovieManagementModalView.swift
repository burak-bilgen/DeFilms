//
//  FavoriteMovieManagementModalView.swift
//  DeFilms
//

import SwiftUI

struct FavoriteMovieManagementModalView: View {
    let movie: FavoriteMovie
    let destinations: [FavoriteMovieDestination]
    let moveMovie: (UUID) -> Void
    let createListAndMove: (String) async -> Bool
    let removeMovie: () -> Void

    @FocusState private var isTextFieldFocused: Bool
    @State private var isCreatingList = false
    @State private var listName = ""
    @State private var isRemoveConfirmationPresented = false
    @State private var pendingDestination: FavoriteMovieDestination?

    private var proposedListName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        FavoritesModalShell(regularMaxWidth: 390, accessibilityMaxWidth: 430) { dismissAnimated in
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header(dismissAnimated: dismissAnimated)
                movieSummary

                if isCreatingList {
                    createListContent(dismissAnimated: dismissAnimated)
                } else {
                    destinationContent(dismissAnimated: dismissAnimated)
                }
            }
            .alert(
                Localization.string("favorites.move.title"),
                isPresented: Binding(
                    get: { pendingDestination != nil },
                    set: { isPresented in
                        if !isPresented {
                            pendingDestination = nil
                        }
                    }
                )
            ) {
                Button(Localization.string("favorites.move.confirm")) {
                    guard let pendingDestination else { return }
                    moveMovie(pendingDestination.id)
                    dismissAnimated()
                }
                Button(Localization.string("common.cancel"), role: .cancel) {
                    pendingDestination = nil
                }
            } message: {
                Text(
                    Localization.string(
                        pendingDestination?.alreadyContainsMovie == true
                            ? "favorites.move.confirm.merge.message"
                            : "favorites.move.confirm.message",
                        movie.title,
                        pendingDestination?.list.name ?? ""
                    )
                )
            }
            .alert(
                Localization.string("favorites.remove.movie.title"),
                isPresented: $isRemoveConfirmationPresented
            ) {
                Button(Localization.string("favorites.remove.movie.confirm"), role: .destructive) {
                    removeMovie()
                    dismissAnimated()
                }
                Button(Localization.string("common.cancel"), role: .cancel) {}
            } message: {
                Text(Localization.string("favorites.remove.movie.message", movie.title))
            }
        }
        .animation(AppAnimation.gentleSpring, value: isCreatingList)
    }

    private func header(dismissAnimated: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(Localization.string(isCreatingList ? "favorites.create.title" : "favorites.move.title"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text(
                    Localization.string(
                        isCreatingList
                            ? "favorites.create.subtitle.movie"
                            : "favorites.move.message",
                        movie.title
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                dismissAnimated()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(AppPalette.cardAccentBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, AppSpacing.xs)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppPalette.border)
                .frame(height: 1)
        }
    }

    private var movieSummary: some View {
        HStack(spacing: AppSpacing.md) {
            PosterImageView(
                url: movie.asMovie.posterURL,
                cornerRadius: 14,
                placeholderSystemImage: "film"
            )
            .frame(width: 56, height: 84)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(movie.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(movie.releaseYear == "--" ? Localization.string("favorites.move.title") : movie.releaseYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func destinationContent(dismissAnimated: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if destinations.isEmpty {
                Text(Localization.string("favorites.create.subtitle.movie"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(destinations) { destination in
                            Button {
                                pendingDestination = destination
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                        Text(destination.list.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        HStack(spacing: AppSpacing.xs) {
                                            Text(Localization.string("favorites.count", destination.list.movies.count))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)

                                            if destination.alreadyContainsMovie {
                                                Text(Localization.string("favorites.move.destination.contains"))
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.orange)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                    .layoutPriority(1)

                                    Spacer(minLength: 0)

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .fixedSize()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardBackground)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: min(CGFloat(max(destinations.count, 1)) * 92, 280))
            }

            HStack(spacing: AppSpacing.sm) {
                Button {
                    withAnimation(AppAnimation.gentleSpring) {
                        isCreatingList = true
                    }
                    isTextFieldFocused = true
                } label: {
                    Label(Localization.string("favorites.picker.newList"), systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppDimension.prominentButtonHeight)
                        .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardAccentBackground)
                }
                .buttonStyle(.plain)

                Button(Localization.string("favorites.remove.movie.confirm"), role: .destructive) {
                    isRemoveConfirmationPresented = true
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: AppDimension.prominentButtonHeight)
                .background(Color.red.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                        .stroke(Color.red.opacity(0.28), lineWidth: 1)
                )
                .buttonStyle(.plain)
            }
        }
    }

    private func createListContent(dismissAnimated: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Localization.string("favorites.picker.placeholder"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(Localization.string("favorites.picker.placeholder"), text: $listName)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 52)
                    .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardBackground)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        Task {
                            await submitNewList(dismissAnimated: dismissAnimated)
                        }
                    }
            }

            if proposedListName.isEmpty {
                Text(Localization.string("favorites.form.requiredHint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.sm) {
                Button(Localization.string("common.cancel")) {
                    withAnimation(AppAnimation.gentleSpring) {
                        isCreatingList = false
                        listName = ""
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: AppDimension.prominentButtonHeight)
                .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardAccentBackground)
                .buttonStyle(.plain)

                Button {
                    Task {
                        await submitNewList(dismissAnimated: dismissAnimated)
                    }
                } label: {
                    Text(Localization.string("favorites.action.create"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .disabled(proposedListName.isEmpty)
                .opacity(proposedListName.isEmpty ? 0.5 : 1)
            }
        }
    }

    private func submitNewList(dismissAnimated: @escaping () -> Void) async {
        guard !proposedListName.isEmpty else { return }
        let moved = await createListAndMove(proposedListName)
        if moved {
            dismissAnimated()
        }
    }
}
