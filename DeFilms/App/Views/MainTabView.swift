
import SwiftUI
import Combine

struct MainTabView: View {
    let container: AppContainer
    let listsStore: ListsStore
    @EnvironmentObject private var preferences: AppPreferences

    @State private var selection: Tab = .movies
    @StateObject private var movieCoordinator = MovieCoordinator()
    @StateObject private var aiCoordinator = MovieCoordinator()
    @StateObject private var listsCoordinator = ListsCoordinator()
    @StateObject private var settingsCoordinator = SettingsCoordinator()
    @StateObject private var moviesViewModel: MovieSearchViewModel
    @StateObject private var listsViewModel: ListsViewModel
    @StateObject private var movieStatusStore: UserMovieStatusStore

    init(container: AppContainer, listsStore: ListsStore) {
        self.container = container
        self.listsStore = listsStore
        _moviesViewModel = StateObject(wrappedValue: container.moviesFactory.makeSearchViewModel())
        _listsViewModel = StateObject(
            wrappedValue: container.listsFactory.makeListsViewModel(
                listsStore: listsStore
            )
        )
        _movieStatusStore = StateObject(wrappedValue: container.movieStatusStore)
    }

    var body: some View {
        TabView(selection: $selection) {
            moviesTab
                .tag(Tab.movies)
                .tabItem {
                    Label(Localization.string("tab.movies"), systemImage: selection == .movies ? "movieclapper.fill" : "movieclapper")
                }

            aiTab
                .tag(Tab.ai)
                .tabItem {
                    Label(Localization.string("tab.ai"), systemImage: "sparkles")
                }

            listsTab
                .tag(Tab.lists)
                .tabItem {
                    Label(Localization.string("tab.lists"), systemImage: selection == .lists ? "rectangle.stack.badge.play.fill" : "rectangle.stack.badge.play")
                }

            settingsTab
                .tag(Tab.settings)
                .tabItem {
                    Label(Localization.string("tab.settings"), systemImage: selection == .settings ? "gearshape.fill" : "gearshape")
                }
        }
        .id(preferences.interfaceLayoutRefreshToken)
        .tint(.primary)
        .animation(AppAnimation.gentleSpring, value: selection)
        .environmentObject(movieStatusStore)
        .relayToast(from: moviesViewModel.$toastItem.eraseToAnyPublisher()) {
            moviesViewModel.clearToast()
        }
    }

    private var moviesTab: some View {
        NavigationStack(path: $movieCoordinator.path) {
            MoviesView(
                viewModel: moviesViewModel,
                openLists: {
                    selection = .lists
                }
            )
            .navigationDestination(for: MovieRoute.self) { route in
                switch route {
                case let .detail(movie):
                    MovieDetailView(viewModel: container.moviesFactory.makeDetailViewModel(movie: movie))
                }
            }
        }
        .environmentObject(movieCoordinator)
    }

    private var aiTab: some View {
        NavigationStack(path: $aiCoordinator.path) {
            MovieAIPicksView(
                moviesViewModel: moviesViewModel,
                listsStore: listsStore
            )
            .navigationDestination(for: MovieRoute.self) { route in
                switch route {
                case let .detail(movie):
                    MovieDetailView(viewModel: container.moviesFactory.makeDetailViewModel(movie: movie))
                }
            }
        }
        .environmentObject(aiCoordinator)
    }

    private var listsTab: some View {
        NavigationStack(path: $listsCoordinator.path) {
            ListsView(
                viewModel: listsViewModel
            )
            .navigationDestination(for: ListsRoute.self) { route in
                switch route {
                case let .list(listID):
                    MovieListDetailView(
                        viewModel: container.listsFactory.makeListDetailViewModel(
                            listID: listID,
                            listsStore: listsStore
                        )
                    )
                case let .movie(movie):
                    MovieDetailView(viewModel: container.moviesFactory.makeDetailViewModel(movie: movie))
                }
            }
        }
        .environmentObject(listsCoordinator)
    }

    private var settingsTab: some View {
        NavigationStack(path: $settingsCoordinator.path) {
            SettingsView(
                container: container,
                viewModel: container.settingsFactory.makeSettingsViewModel()
            )
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .signIn:
                    SignInView(viewModel: container.settingsFactory.makeSignInViewModel())
                case .signUp:
                    SignUpView(viewModel: container.settingsFactory.makeSignUpViewModel())
                case .changePassword:
                    ChangePasswordView(viewModel: container.settingsFactory.makeChangePasswordViewModel())
                }
            }
        }
        .environmentObject(settingsCoordinator)
    }
}

private enum Tab: Hashable {
    case movies
    case ai
    case lists
    case settings
}
