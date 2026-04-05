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

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
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
}

private extension NSManagedObjectContext {
    func performSynchronously<T>(_ work: (NSManagedObjectContext) throws -> T) throws -> T {
        var result: Result<T, Error>?

        performAndWait {
            result = Result {
                try work(self)
            }
        }

        return try result!.get()
    }
}
