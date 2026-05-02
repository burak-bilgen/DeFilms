
import Combine
import Foundation
import SwiftUI

@MainActor
final class ListsStore: ObservableObject, ListsStoreManaging {
    @Published private(set) var lists: [MovieList] = []
    @Published private(set) var toastItem: ToastItem?

    private let listsService: ListsServicing
    private let sessionManager: AuthSessionManager
    private var cancellables: Set<AnyCancellable> = []
    private var activeRefreshRequestID = UUID()
    private var hasLoadedLists = false
    private var refreshTask: Task<Void, Never>?

    var listsPublisher: AnyPublisher<[MovieList], Never> {
        $lists.eraseToAnyPublisher()
    }

    init(
        listsService: ListsServicing,
        sessionManager: AuthSessionManager
    ) {
        self.listsService = listsService
        self.sessionManager = sessionManager

        sessionManager.$session
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.hasLoadedLists = false
                    self.startRefresh()
                }
            }
            .store(in: &cancellables)

        startRefresh()
    }

    func createList(named name: String) async -> MovieList? {
        await ensureListsLoaded()

        if let matchingList = list(named: name) {
            return matchingList
        }

        do {
            let list = try await listsService.createList(named: name, lists: lists)
            await refreshLists()
            AppLogger.log("Created movie list", category: .lists, level: .success)
            toastItem = .success(Localization.string("lists.toast.listCreated"))
            return list
        } catch ListsServiceError.invalidListName {
            return nil
        } catch ListsServiceError.duplicateListName {
            if let matchingList = list(named: name) {
                return matchingList
            }
            toastItem = .error(Localization.string("lists.toast.duplicateList"))
            return nil
        } catch {
            AppLogger.log("Failed to create movie list", category: .lists, level: .error)
            toastItem = .error(Localization.string("lists.toast.genericError"))
            return nil
        }
    }

    func add(movie: Movie, to listID: UUID) async {
        await ensureListsLoaded()
        guard isMovieInList(movieID: movie.id, listID: listID) == false else { return }

        do {
            try await listsService.add(movie: movie, to: listID)
            await refreshLists()
            AppLogger.log("Added movie to lists", category: .lists, level: .success)
        } catch {
            AppLogger.log("Failed to add movie to lists", category: .lists, level: .error)
            toastItem = .error(Localization.string("lists.toast.genericError"))
            return
        }
    }

    func remove(movieID: Int, from listID: UUID) async {
        await ensureListsLoaded()
        guard isMovieInList(movieID: movieID, listID: listID) else { return }

        do {
            try await listsService.remove(movieID: movieID, from: listID)
            await refreshLists()
            AppLogger.log("Removed movie from list", category: .lists, level: .success)
        } catch {
            AppLogger.log("Failed to remove movie from list", category: .lists, level: .error)
            toastItem = .error(Localization.string("lists.toast.genericError"))
            return
        }
    }

    func renameList(listID: UUID, name: String) async -> Bool {
        await ensureListsLoaded()

        if let existingList = list(withID: listID),
           normalizedListName(existingList.name) == normalizedListName(name) {
            return true
        }

        do {
            try await listsService.renameList(listID: listID, name: name, lists: lists)
            await refreshLists()
            toastItem = .success(Localization.string("lists.toast.listRenamed"))
            return true
        } catch ListsServiceError.invalidListName {
            return false
        } catch ListsServiceError.duplicateListName {
            toastItem = .error(Localization.string("lists.toast.duplicateList"))
            return false
        } catch {
            toastItem = .error(Localization.string("lists.toast.genericError"))
            return false
        }
    }

    func deleteList(listID: UUID) async {
        await ensureListsLoaded()
        guard list(withID: listID) != nil else { return }

        do {
            try await listsService.deleteList(listID: listID)
            await refreshLists()
            toastItem = .success(Localization.string("lists.toast.listDeleted"))
        } catch {
            toastItem = .error(Localization.string("lists.toast.genericError"))
        }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async {
        await ensureListsLoaded()
        guard sourceListID != destinationListID else { return }
        guard isMovieInList(movieID: movieID, listID: sourceListID) else { return }
        guard list(withID: destinationListID) != nil else { return }

        let destinationAlreadyContainsMovie = isMovieInList(movieID: movieID, listID: destinationListID)

        do {
            try await listsService.move(
                movieID: movieID,
                from: sourceListID,
                to: destinationListID
            )
            await refreshLists()
            let toastKey = destinationAlreadyContainsMovie
                ? "lists.toast.movieMerged"
                : "lists.toast.movieMoved"
            toastItem = .success(Localization.string(toastKey))
        } catch {
            toastItem = .error(Localization.string("lists.toast.genericError"))
        }
    }

    func clearToast() {
        toastItem = nil
    }

    func isMovieInAnyList(movieID: Int) -> Bool {
        lists.contains { list in
            list.movies.contains { $0.id == movieID }
        }
    }

    func isMovieInList(movieID: Int, listID: UUID) -> Bool {
        guard let list = lists.first(where: { $0.id == listID }) else { return false }
        return list.movies.contains { $0.id == movieID }
    }

    func listIDs(containing movieID: Int) -> Set<UUID> {
        Set(
            lists.compactMap { list in
                list.movies.contains(where: { $0.id == movieID }) ? list.id : nil
            }
        )
    }

    func list(named name: String) -> MovieList? {
        let normalizedName = normalizedListName(name)
        return lists.first { normalizedListName($0.name) == normalizedName }
    }

    var totalMovieCount: Int {
        lists.reduce(0) { $0 + $1.movies.count }
    }

    func list(withID listID: UUID) -> MovieList? {
        lists.first(where: { $0.id == listID })
    }

    private func startRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.refreshLists()
        }
    }

    private func ensureListsLoaded() async {
        guard hasLoadedLists == false else { return }

        if let refreshTask {
            await refreshTask.value
        }

        if hasLoadedLists == false {
            await refreshLists()
        }
    }

    private func refreshLists() async {
        let requestID = UUID()
        activeRefreshRequestID = requestID

        do {
            let latestLists = try await listsService.loadLists()
            guard activeRefreshRequestID == requestID else { return }
            withAnimation(.easeInOut(duration: 0.24)) {
                lists = latestLists
            }
            hasLoadedLists = true
            AppLogger.log("Lists refreshed", category: .lists)
        } catch {
            guard activeRefreshRequestID == requestID else { return }
            AppLogger.log("Failed to refresh lists", category: .lists, level: .error)
            hasLoadedLists = false
            toastItem = .error(Localization.string("lists.toast.genericError"))
        }
    }

    private func normalizedListName(_ name: String) -> String {
        name.normalizedForLookup
    }
}
