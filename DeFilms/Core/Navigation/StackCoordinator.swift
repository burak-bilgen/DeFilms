
import Combine
import Foundation

@MainActor
class StackCoordinator<Route: Hashable>: ObservableObject {
    @Published var path: [Route] = []

    func show(_ route: Route) {
        path.append(route)
    }

    func reset() {
        path.removeAll()
    }
}
