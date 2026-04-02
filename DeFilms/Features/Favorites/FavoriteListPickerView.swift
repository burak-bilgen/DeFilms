//
//  FavoriteListPickerView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct FavoriteListPickerView: View {
    let movie: Movie

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    @State private var newListName: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section(Localization.string("favorites.picker.section.lists")) {
                    if favoritesStore.lists.isEmpty {
                        Text(Localization.string("favorites.picker.empty"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favoritesStore.lists) { list in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(list.name)
                                        .font(.headline)
                                    Text(Localization.string("favorites.count", list.movies.count))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if favoritesStore.isMovieInList(movieID: movie.id, listID: list.id) {
                                    Button(Localization.string("favorites.action.remove")) {
                                        favoritesStore.remove(movieID: movie.id, from: list.id)
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button(Localization.string("favorites.action.add")) {
                                        favoritesStore.add(movie: movie, to: list.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section(Localization.string("favorites.picker.section.newList")) {
                    HStack {
                        TextField(Localization.string("favorites.picker.placeholder"), text: $newListName)
                        Button(Localization.string("favorites.action.create")) {
                            if let list = favoritesStore.createList(named: newListName) {
                                favoritesStore.add(movie: movie, to: list.id)
                                newListName = ""
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle(Localization.string("favorites.picker.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Localization.string("common.close")) { dismiss() }
                }
            }
        }
    }
}
