//
//  ManagedCache.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 23/07/2024.
//

import CoreData

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try deleteCache(in: context)
        return ManagedCache(context: context)
    }
    
    static func deleteCache(in context: NSManagedObjectContext) throws {
        try ManagedCache.find(in: context).map(context.delete).map(context.save)
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
