//
//  MainTabView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MoviesView()
                .tabItem {
                    Label("Filmler", systemImage: "popcorn.fill")
                }

            FavoritesView()
                .tabItem {
                    Label("Favoriler", systemImage: "heart.stack.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.accentColor)
    }
}
