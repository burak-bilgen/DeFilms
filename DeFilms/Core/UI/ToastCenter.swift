//
//  ToastCenter.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

final class ToastCenter: ObservableObject {
    @Published var item: ToastItem?

    func show(message: String, style: ToastItem.Style = .info) {
        item = ToastItem(message: message, style: style)
    }

    func showError(_ message: String) {
        show(message: message, style: .error)
    }

    func showSuccess(_ message: String) {
        show(message: message, style: .success)
    }
}
