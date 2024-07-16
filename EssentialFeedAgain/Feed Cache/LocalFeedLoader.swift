//
//  LocalFeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 15/07/2024.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage]) async throws {
        try await store.deleteCachedFeed()
        try await store.insert(feed.local, timestamp: currentDate())
    }
    
    public func load() async throws -> [FeedImage] {
        let (feed, timestamp) = try await store.retrieve()
        guard FeedCachePolicy.validate(timestamp, against: currentDate()) else {
            return []
        }
        
        return feed.models
    }
    
    public func validateCache() async {
        do {
            _ = try await store.retrieve()
        } catch {
            try? await store.deleteCachedFeed()
        }
    }
}

private extension [FeedImage] {
    var local: [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension [LocalFeedImage] {
    var models: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
