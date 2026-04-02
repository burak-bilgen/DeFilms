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
                Section("Listeler") {
                    if favoritesStore.lists.isEmpty {
                        Text("Henüz liste yok. Yeni bir liste oluşturun.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favoritesStore.lists) { list in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(list.name)
                                        .font(.headline)
                                    Text("\(list.movies.count) film")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if favoritesStore.isMovieInList(movieID: movie.id, listID: list.id) {
                                    Button("Çıkar") {
                                        favoritesStore.remove(movieID: movie.id, from: list.id)
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button("Ekle") {
                                        favoritesStore.add(movie: movie, to: list.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Yeni Liste") {
                    HStack {
                        TextField("Liste adı", text: $newListName)
                        Button("Oluştur") {
                            if let list = favoritesStore.createList(named: newListName) {
                                favoritesStore.add(movie: movie, to: list.id)
                                newListName = ""
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Favori Listesi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
