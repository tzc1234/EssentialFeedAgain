//
//  CoreDataFeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 22/07/2024.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
    public init() {
        
    }
    
    public func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date)? {
        nil
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        
    }
    
    public func deleteCachedFeed() async throws {
        
    }
}
