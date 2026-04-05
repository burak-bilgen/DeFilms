//
//  StackCoordinator.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
class StackCoordinator<Route: Hashable>: ObservableObject {
    @Published var path: [Route] = []

    // Keep navigation verbs explicit so feature views read like intent, not array mutation.
    func show(_ route: Route) {
        path.append(route)
    }

    func reset() {
        path.removeAll()
    }
}
