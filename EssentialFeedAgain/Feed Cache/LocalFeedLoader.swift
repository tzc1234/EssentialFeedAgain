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
    
    public init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader: FeedCache {
    public func save(_ feed: [FeedImage]) async throws {
        try await store.deleteCachedFeed()
        try await store.insert(feed.local, timestamp: currentDate())
    }
}

extension LocalFeedLoader: FeedLoader {
    public func load() async throws -> [FeedImage] {
        let cache = try await store.retrieve()
        guard let cache, FeedCachePolicy.validate(cache.timestamp, against: currentDate()) else {
            return []
        }
        
        return cache.feed.models
    }
}

extension LocalFeedLoader {
    public func validateCache() async throws {
        do {
            let cache = try await store.retrieve()
            guard let cache, !FeedCachePolicy.validate(cache.timestamp, against: currentDate()) else {
                return
            }
        } catch {
            return try await store.deleteCachedFeed()
        }
        
        try await store.deleteCachedFeed()
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
