
import Combine
import Foundation

enum AppModalRoute: Identifiable {
    case signIn
    case signUp

    var id: Self { self }
}

@MainActor
final class AppFlowCoordinator: ObservableObject {
    @Published var modalRoute: AppModalRoute?

    func presentSignIn() {
        guard modalRoute == nil else { return }
        modalRoute = .signIn
    }

    func presentSignUp() {
        guard modalRoute == nil else { return }
        modalRoute = .signUp
    }

    func dismissModal() {
        modalRoute = nil
    }
}
