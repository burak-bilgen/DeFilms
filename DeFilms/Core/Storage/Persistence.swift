//
//  Persistence.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DeFilms")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        if loadPersistentStoresWithRecovery() == false {
            AppLogger.log(
                "Persistent store recovery failed, falling back to in-memory store",
                category: .persistence,
                level: .error
            )
            configureInMemoryFallbackStore()
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func performRead<T>(_ work: (NSManagedObjectContext) throws -> T) throws -> T {
        let context = newBackgroundContext()
        return try context.performSynchronously(work)
    }

    func performWrite<T>(_ work: (NSManagedObjectContext) throws -> T) throws -> T {
        let context = newBackgroundContext()
        let value = try context.performSynchronously(work)

        if context.hasChanges {
            try context.performSynchronously { context in
                try context.save()
            }
        }

        return value
    }

    func resetAllData() throws {
        try performWrite { context in
            let entityNames = [
                "FavoriteMovieEntity",
                "FavoriteListEntity",
                "RecentSearchEntity"
            ]

            for entityName in entityNames {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                deleteRequest.resultType = .resultTypeObjectIDs

                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [container.viewContext, context]
                )
            }
        }
    }

    private func loadPersistentStoresWithRecovery() -> Bool {
        if loadPersistentStores() {
            return true
        }

        AppLogger.log("Persistent store load failed, attempting reset", category: .persistence, level: .error)

        guard resetPersistentStores() else {
            AppLogger.log("Persistent store reset failed", category: .persistence, level: .error)
            return false
        }

        let didRecover = loadPersistentStores()
        AppLogger.log(
            didRecover ? "Persistent store recovered after reset" : "Persistent store could not be recovered after reset",
            category: .persistence,
            level: didRecover ? .success : .error
        )
        return didRecover
    }

    private func loadPersistentStores() -> Bool {
        var loadError: NSError?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error as NSError?
            semaphore.signal()
        }

        let didFinish = semaphore.wait(timeout: .now() + 5) == .success
        if !didFinish {
            AppLogger.log(
                "Persistent store load timed out",
                category: .persistence,
                level: .error
            )
            return false
        }

        return loadError == nil
    }

    private func resetPersistentStores() -> Bool {
        let coordinator = container.persistentStoreCoordinator

        for description in container.persistentStoreDescriptions {
            guard let storeURL = description.url else { continue }
            guard FileManager.default.fileExists(atPath: storeURL.path) else { continue }

            do {
                if let existingStore = coordinator.persistentStores.first(where: { $0.url == storeURL }) {
                    try coordinator.remove(existingStore)
                }
            } catch {
                AppLogger.log("Failed to detach persistent store before reset", category: .persistence, level: .error)
            }

            do {
                try coordinator.destroyPersistentStore(
                    at: storeURL,
                    type: NSPersistentStore.StoreType(rawValue: description.type),
                    options: description.options
                )
            } catch {
                AppLogger.log("Failed to destroy persistent store during reset", category: .persistence, level: .error)
                return false
            }
        }

        return true
    }

    private func configureInMemoryFallbackStore() {
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: NSError?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error as NSError?
            semaphore.signal()
        }

        let didFinish = semaphore.wait(timeout: .now() + 5) == .success
        if !didFinish {
            AppLogger.log(
                "In-memory fallback store load timed out",
                category: .persistence,
                level: .error
            )
            return
        }

        if loadError != nil {
            AppLogger.log(
                "In-memory fallback store could not be loaded",
                category: .persistence,
                level: .error
            )
        }
    }
}

private extension NSManagedObjectContext {
    func performSynchronously<T>(_ work: (NSManagedObjectContext) throws -> T) throws -> T {
        var result: Result<T, Error>?

        performAndWait {
            result = Result {
                try work(self)
            }
        }

        guard let result else {
            throw NSError(
                domain: "DeFilms.Persistence",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Managed object context work did not produce a result."]
            )
        }

        return try result.get()
    }
}
