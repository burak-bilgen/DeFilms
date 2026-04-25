
import SwiftUI

struct NewFavoriteListView: View {
    let movie: Movie?
    let onListCreated: ((FavoriteList) -> Void)?

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isTextFieldFocused: Bool
    @State private var listName: String = ""

    private var proposedListName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(movie: Movie?, onListCreated: ((FavoriteList) -> Void)? = nil) {
        self.movie = movie
        self.onListCreated = onListCreated
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Localization.string("favorites.create.heading"))
                    .font(.title2.weight(.bold))

                Text(Localization.string(movie == nil ? "favorites.create.subtitle.empty" : "favorites.create.subtitle.movie"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(Localization.string("favorites.picker.placeholder"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(Localization.string("favorites.picker.placeholder"), text: $listName)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel(Localization.string("favorites.picker.placeholder"))
                    .accessibilityIdentifier("favorites.create.textField")
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(AppPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        Task {
                            await createList()
                        }
                    }
            }

            if proposedListName.isEmpty {
                Text(Localization.string("favorites.form.requiredHint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await createList()
                }
            } label: {
                Text(Localization.string("favorites.action.create"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryProminentButtonStyle())
            .disabled(proposedListName.isEmpty)
            .opacity(proposedListName.isEmpty ? 0.5 : 1)
            .accessibilityLabel(Localization.string("favorites.action.create"))
            .accessibilityIdentifier("favorites.create.submit")

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.lg)
        .navigationTitle(Localization.string("favorites.create.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(Localization.string("common.cancel")) {
                    dismiss()
                }
            }
        }
        .background(AppPalette.screenBackground)
        .task {
            isTextFieldFocused = true
        }
    }

    private func createList() async {
        guard !proposedListName.isEmpty else { return }
        guard let list = await favoritesStore.createList(named: listName) else { return }
        if let movie {
            await favoritesStore.add(movie: movie, to: list.id)
        }
        onListCreated?(list)
        dismiss()
    }
}
