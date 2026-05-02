
import SwiftUI

struct MovieListPickerModalView: View {
    let movie: Movie

    @EnvironmentObject private var listsStore: ListsStore

    @FocusState private var isTextFieldFocused: Bool
    @State private var listPendingRemoval: MovieList?
    @State private var isCreatingList = false
    @State private var listName = ""

    private var proposedListName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ListsModalShell(regularMaxWidth: 380, accessibilityMaxWidth: 420) { dismissAnimated in
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header(dismissAnimated: dismissAnimated)

                if isCreatingList {
                    createListContent(dismissAnimated: dismissAnimated)
                } else {
                    pickerContent
                }
            }
        }
        .animation(AppAnimation.gentleSpring, value: isCreatingList)
        .alert(
            Localization.string("lists.remove.movie.title"),
            isPresented: Binding(
                get: { listPendingRemoval != nil },
                set: { isPresented in
                    if !isPresented {
                        listPendingRemoval = nil
                    }
                }
            )
        ) {
            Button(Localization.string("lists.remove.movie.confirm"), role: .destructive) {
                if let listPendingRemoval {
                    Task {
                        await listsStore.remove(movieID: movie.id, from: listPendingRemoval.id)
                        self.listPendingRemoval = nil
                    }
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {
                listPendingRemoval = nil
            }
        } message: {
            Text(Localization.string("lists.remove.from.list.message", listPendingRemoval?.name ?? ""))
        }
        .task {
            if listsStore.lists.isEmpty {
                isCreatingList = true
                isTextFieldFocused = true
            }
        }
    }

    private func header(dismissAnimated: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(Localization.string(isCreatingList ? "lists.create.title" : "lists.picker.title"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text(
                    Localization.string(
                        isCreatingList
                            ? (listsStore.lists.isEmpty ? "lists.create.subtitle.empty" : "lists.create.subtitle.movie")
                            : "lists.picker.subtitle"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    @ViewBuilder
    private var pickerContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(listsStore.lists) { list in
                        Button {
                            if listsStore.isMovieInList(movieID: movie.id, listID: list.id) {
                                listPendingRemoval = list
                            } else {
                                Task {
                                    await listsStore.add(movie: movie, to: list.id)
                                }
                            }
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text(list.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text(Localization.string("lists.count", list.movies.count))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: listsStore.isMovieInList(movieID: movie.id, listID: list.id) ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(
                                        listsStore.isMovieInList(movieID: movie.id, listID: list.id)
                                            ? Color(red: 0.96, green: 0.74, blue: 0.22)
                                            : .primary
                                    )
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardBackground)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Localization.string("lists.accessibility.listSummary", list.name, list.movies.count))
                    }
                }
            }
            .frame(maxHeight: min(CGFloat(max(listsStore.lists.count, 1)) * 72, 280))

            Button {
                withAnimation(AppAnimation.gentleSpring) {
                    isCreatingList = true
                }
                isTextFieldFocused = true
            } label: {
                Label(Localization.string("lists.picker.newList"), systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppDimension.prominentButtonHeight)
                    .appCardSurface(cornerRadius: AppCornerRadius.md, background: AppPalette.cardAccentBackground)
            }
            .buttonStyle(.plain)
        }
    }

    private func createListContent(dismissAnimated: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Localization.string("lists.picker.placeholder"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(Localization.string("lists.picker.placeholder"), text: $listName)
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
                            await createList(dismissAnimated: dismissAnimated)
                        }
                    }
            }

            if proposedListName.isEmpty {
                Text(Localization.string("lists.form.requiredHint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.sm) {
                if !listsStore.lists.isEmpty {
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
                }

                Button {
                    Task {
                        await createList(dismissAnimated: dismissAnimated)
                    }
                } label: {
                    Text(Localization.string("lists.action.create"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .disabled(proposedListName.isEmpty)
                .opacity(proposedListName.isEmpty ? 0.5 : 1)
            }
        }
    }

    private func createList(dismissAnimated: @escaping () -> Void) async {
        guard !proposedListName.isEmpty else { return }
        guard let list = await listsStore.createList(named: proposedListName) else { return }
        await listsStore.add(movie: movie, to: list.id)
        dismissAnimated()
        _ = list
    }
}
