//
//  MovieFilterSheet.swift
//  DeFilms
//

import SwiftUI

struct MovieFilterSheet: View {
    @ObservedObject var viewModel: MovieSearchViewModel
    @Environment(\.dismiss) private var dismiss

    private let genreColumns = [
        GridItem(.adaptive(minimum: 110), spacing: AppSpacing.sm)
    ]

    var body: some View {
        Form {
            Section(Localization.string("movies.filter.title")) {
                TextField(Localization.string("movies.filter.year"), text: $viewModel.filterYear)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: viewModel.filterYear) { newValue in
                        viewModel.filterYear = String(newValue.filter(\.isNumber).prefix(4))
                    }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text(Localization.string("movies.filter.rating"))
                        Spacer()
                        Text(String(format: "%.0f+", viewModel.minRating))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $viewModel.minRating, in: 0...10, step: 1)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(Localization.string("movies.filter.genre"))
                        .font(.subheadline.weight(.semibold))

                    LazyVGrid(columns: genreColumns, alignment: .leading, spacing: AppSpacing.sm) {
                        genreChip(
                            title: Localization.string("movies.filter.genre.all"),
                            isSelected: viewModel.selectedGenreID == nil
                        ) {
                            viewModel.selectedGenreID = nil
                        }

                        ForEach(viewModel.genres) { genre in
                            genreChip(
                                title: genre.name,
                                isSelected: viewModel.selectedGenreID == genre.id
                            ) {
                                viewModel.selectedGenreID = genre.id
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Localization.string("movies.filter.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(Localization.string("movies.filter.reset")) {
                    viewModel.filterYear = ""
                    viewModel.minRating = 0
                    viewModel.selectedGenreID = nil
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(Localization.string("common.done")) {
                    dismiss()
                }
            }
        }
    }

    private func genreChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .padding(.horizontal, AppSpacing.xs)
                .background(isSelected ? Color.primary : AppPalette.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(AppPalette.border.opacity(isSelected ? 0 : 1), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
