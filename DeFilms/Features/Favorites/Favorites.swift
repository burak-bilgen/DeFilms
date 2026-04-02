//
//  Favorites.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 80))
                    .foregroundColor(Color.accentColor)
                
                Text("Favori Listelerin")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground"))
            .navigationTitle("Favoriler")
        }
    }
}
