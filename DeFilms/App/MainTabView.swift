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
                    Label("Filmler", systemImage: "movieclapper.fill")
                }

            FavoritesView()
                .tabItem {
                    Label("Favoriler", systemImage: "rectangle.stack.badge.play")
                }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "filemenu.and.selection")
                }
        }
        .tint(Color.accentColor)
    }
}

