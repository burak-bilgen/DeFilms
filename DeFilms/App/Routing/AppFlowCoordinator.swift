//
//  AppFlowCoordinator.swift
//  DeFilms
//

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
        modalRoute = .signIn
    }

    func presentSignUp() {
        modalRoute = .signUp
    }

    func dismissModal() {
        modalRoute = nil
    }
}
