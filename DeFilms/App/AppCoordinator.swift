//
//  AppCoordinator.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
final class NavigationCoordinator<Route: Hashable>: ObservableObject {
    @Published var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }
}

enum MovieRoute: Hashable {
    case detail(Movie)
}

enum FavoritesRoute: Hashable {
    case list(UUID)
    case movie(Movie)
}
