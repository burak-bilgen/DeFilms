//
//  MovieFilterSheet.swift
//  DeFilms
//

import SwiftUI

struct MovieFilterSheet: View {
    @ObservedObject var viewModel: MovieSearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(Localization.string("movies.filter.title")) {
                TextField(Localization.string("movies.filter.year"), text: $viewModel.filterYear)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.filterYear) { newValue in
                        viewModel.filterYear = String(newValue.filter(\.isNumber).prefix(4))
                    }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(Localization.string("movies.filter.rating"))
                        Spacer()
                        Text(String(format: "%.0f+", viewModel.minRating))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $viewModel.minRating, in: 0...10, step: 1)
                }

                Picker(Localization.string("movies.filter.genre"), selection: $viewModel.selectedGenreID) {
                    Text(Localization.string("movies.filter.genre.all")).tag(Int?.none)
                    ForEach(viewModel.genres) { genre in
                        Text(genre.name).tag(Optional(genre.id))
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
}
