//
//  FavoriteMovieManagementModalView.swift
//  DeFilms
//

import SwiftUI

struct FavoriteMovieManagementModalView: View {
    let movie: FavoriteMovie
    let destinationLists: [FavoriteList]
    let moveMovie: (UUID) -> Void
    let createListAndMove: (String) async -> Bool
    let removeMovie: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @FocusState private var isTextFieldFocused: Bool
    @State private var isPresented = false
    @State private var isCreatingList = false
    @State private var listName = ""
    @State private var isRemoveConfirmationPresented = false
    @State private var pendingDestinationList: FavoriteList?
    @State private var isDismissing = false

    private var proposedListName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimated()
                }

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                movieSummary

                if isCreatingList {
                    createListContent
                } else {
                    destinationContent
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 430 : 390)
            .background(modalBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                    .stroke(AppPalette.border.opacity(1.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 28, x: 0, y: 18)
            .padding(.horizontal, AppSpacing.lg)
            .scaleEffect(isPresented ? 1 : 0.92)
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 16)
        }
        .presentationBackground(.clear)
        .animation(AppAnimation.emphasizedSpring, value: isPresented)
        .animation(AppAnimation.gentleSpring, value: isCreatingList)
        .alert(
            Localization.string("favorites.move.title"),
            isPresented: Binding(
                get: { pendingDestinationList != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDestinationList = nil
                    }
                }
            )
        ) {
            Button(Localization.string("favorites.move.confirm")) {
                guard let pendingDestinationList else { return }
                moveMovie(pendingDestinationList.id)
                dismissAnimated()
            }
            Button(Localization.string("common.cancel"), role: .cancel) {
                pendingDestinationList = nil
            }
        } message: {
            Text(
                Localization.string(
                    "favorites.move.confirm.message",
                    movie.title,
                    pendingDestinationList?.name ?? ""
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
        .task {
            isPresented = true
        }
    }

    private var header: some View {
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
                .lineLimit(2)
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
                    .lineLimit(2)

                Text(movie.releaseYear == "--" ? Localization.string("favorites.move.title") : movie.releaseYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var destinationContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if destinationLists.isEmpty {
                Text(Localization.string("favorites.create.subtitle.movie"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(destinationLists) { destination in
                            Button {
                                pendingDestinationList = destination
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                        Text(destination.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)

                                        Text(Localization.string("favorites.count", destination.movies.count))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer(minLength: 0)

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardBackground)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: min(CGFloat(max(destinationLists.count, 1)) * 72, 240))
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
                        .frame(height: AppDimension.controlHeight)
                        .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardAccentBackground)
                }
                .buttonStyle(.plain)

                Button(Localization.string("favorites.remove.movie.confirm"), role: .destructive) {
                    isRemoveConfirmationPresented = true
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: AppDimension.controlHeight)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
                .buttonStyle(.plain)
            }
        }
    }

    private var createListContent: some View {
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
                            await submitNewList()
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
                        await submitNewList()
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

    private var modalBackground: some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
            .fill(AppPalette.screenBackground)
    }

    private func submitNewList() async {
        guard !proposedListName.isEmpty else { return }
        let moved = await createListAndMove(proposedListName)
        if moved {
            dismissAnimated()
        }
    }

    private func dismissAnimated() {
        guard !isDismissing else { return }
        isDismissing = true

        withAnimation(AppAnimation.emphasizedSpring) {
            isPresented = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            dismiss()
        }
    }
}
