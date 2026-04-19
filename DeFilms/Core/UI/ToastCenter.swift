//
//  ToastCenter.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation
import SwiftUI

final class ToastCenter: ObservableObject {
    @Published var item: ToastItem?
    private var dismissalTask: Task<Void, Never>?

    @MainActor
    func show(message: String, style: ToastItem.Style = .info, duration: TimeInterval = 1.8) {
        dismissalTask?.cancel()
        item = ToastItem(message: message, style: style)

        dismissalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.24)) {
                self?.item = nil
            }
            self?.dismissalTask = nil
        }
    }

    func showError(_ message: String) {
        show(message: message, style: .error)
    }

    @MainActor
    func showSuccess(_ message: String) {
        show(message: message, style: .success)
    }

    @MainActor
    func clear() {
        dismissalTask?.cancel()
        dismissalTask = nil
        item = nil
    }
}
