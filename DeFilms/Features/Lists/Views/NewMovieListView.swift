
import SwiftUI

struct NewMovieListView: View {
    let movie: Movie?
    let onListCreated: ((MovieList) -> Void)?

    @EnvironmentObject private var listsStore: ListsStore
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isTextFieldFocused: Bool
    @State private var listName: String = ""

    private var proposedListName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(movie: Movie?, onListCreated: ((MovieList) -> Void)? = nil) {
        self.movie = movie
        self.onListCreated = onListCreated
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Localization.string("lists.create.heading"))
                    .font(.title2.weight(.bold))

                Text(Localization.string(movie == nil ? "lists.create.subtitle.empty" : "lists.create.subtitle.movie"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(Localization.string("lists.picker.placeholder"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(Localization.string("lists.picker.placeholder"), text: $listName)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel(Localization.string("lists.picker.placeholder"))
                    .accessibilityIdentifier("lists.create.textField")
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
                Text(Localization.string("lists.form.requiredHint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await createList()
                }
            } label: {
                Text(Localization.string("lists.action.create"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryProminentButtonStyle())
            .disabled(proposedListName.isEmpty)
            .opacity(proposedListName.isEmpty ? 0.5 : 1)
            .accessibilityLabel(Localization.string("lists.action.create"))
            .accessibilityIdentifier("lists.create.submit")

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.lg)
        .navigationTitle(Localization.string("lists.create.title"))
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
        guard let list = await listsStore.createList(named: listName) else { return }
        if let movie {
            await listsStore.add(movie: movie, to: list.id)
        }
        onListCreated?(list)
        dismiss()
    }
}
