//
//  SearchHistoryView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct SearchHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !history.isEmpty {
                Text("Son Aramalar")
                    .font(.headline)

                ForEach(history, id: \.self) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        Text(item)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}