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
            throw SetupError.modelNotFound
        }
        
        self.container = try Self.loadContainer(for: storeURL, with: model)
        self.context = container.newBackgroundContext()
    }
    
    public func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date)? {
        try await perform { context in
            guard let cache = try ManagedCache.find(in: context) else {
                return nil
            }
           
            return (cache.localFeed, cache.timestamp)
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        try await perform { context in
            let managedCache = try ManagedCache.newUniqueInstance(in: context)
            managedCache.timestamp = timestamp
            managedCache.feed = ManagedCache.images(from: feed, in: context)
            
            try context.save()
        }
    }
    
    public func deleteCachedFeed() async throws {
        
    }
    
    private func perform<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T {
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

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
    }
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: String(describing: ManagedCache.self))
        request.returnsObjectsAsFaults = false
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    static func images(from localFeed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
        NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.url
            return managed
        })
    }
    
    var localFeed: [LocalFeedImage] {
        feed.compactMap { $0 as? ManagedFeedImage }.map(\.local)
    }
}

@objc(ManagedFeedImage)
final class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
    var local: LocalFeedImage {
        LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
    }
}
