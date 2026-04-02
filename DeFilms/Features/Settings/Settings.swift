//
//  Settings.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Tercihler") {
                    Toggle("Karanlık Mod", isOn: .constant(false))
                }
                
                Section("Hesap") {
                    Text("Giriş Yap / Kayıt Ol")
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Ayarlar")
        }
    }
}
