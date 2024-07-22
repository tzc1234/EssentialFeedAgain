//
//  CoreDataFeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 22/07/2024.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL) throws {
        guard let model = Self.model else {
            throw LoadingError.modelNotFound
        }
        
        self.container = try Self.loadContainer(for: storeURL, with: model)
        self.context = container.newBackgroundContext()
    }
    
    public func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date)? {
        try await context.perform { [context] in
            let request = NSFetchRequest<ManagedCache>(entityName: String(describing: ManagedCache.self))
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            guard let cache = try context.fetch(request).first else {
                return nil
            }
            
            let feed = cache.feed
                .compactMap { $0 as? ManagedFeedImage }
                .map {
                    LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)
                }
           
            return (feed, cache.timestamp)
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        try await context.perform { [context] in
            let managedCache = ManagedCache(context: context)
            managedCache.timestamp = timestamp
            managedCache.feed = NSOrderedSet(array: feed.map { local in
                let managedFeedImage = ManagedFeedImage(context: context)
                managedFeedImage.id = local.id
                managedFeedImage.imageDescription = local.description
                managedFeedImage.location = local.location
                managedFeedImage.url = local.url
                return managedFeedImage
            })
            
            try context.save()
        }
    }
    
    public func deleteCachedFeed() async throws {
        
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
    enum LoadingError: Error {
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
            throw LoadingError.loadContainerFailed
        }
        
        return container
    }
}

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
final class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}
