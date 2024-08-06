//
//  CoreDataFeedStore+FeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

extension CoreDataFeedStore: FeedStore {
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
        try await perform { context in
            try ManagedCache.delete(in: context)
        }
    }
}
