//
//  CoreDataFeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 22/07/2024.
//

import CoreData

public final class CoreDataFeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL) throws {
        guard let model = Self.model else {
            throw SetupError.modelNotFound
        }
        
        self.container = try Self.loadContainer(for: storeURL, with: model)
        self.context = container.newBackgroundContext()
    }
    
    func perform<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T {
        try await context.perform { [context] in
            try block(context)
        }
    }
    
    deinit {
        cleanUpReferencesToPersistentStore()
    }
    
    private func cleanUpReferencesToPersistentStore() {
        context.performAndWait {
            let coordinator = container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
}

extension CoreDataFeedStore {
    enum SetupError: Error {
        case modelNotFound
        case loadContainerFailed
    }
    
    private static let modelName = "FeedStore"
    private static let model = getModel()
    
    private static func getModel() -> NSManagedObjectModel? {
        guard let url = Bundle(for: Self.self).url(forResource: modelName, withExtension: "momd") else {
            return nil
        }
        
        return NSManagedObjectModel(contentsOf: url)
    }
    
    private static func loadContainer(for url: URL, with model: NSManagedObjectModel) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url)]
        
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        
        if loadError != nil {
            throw SetupError.loadContainerFailed
        }
        
        return container
    }
}
