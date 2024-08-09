//
//  FeedLoaderCacheDecorator.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 09/08/2024.
//

import EssentialFeedAgain

public final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let cache: FeedCache
    
    public init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func load() async throws -> [FeedImage] {
        let feed = try await decoratee.load()
        try? await cache.save(feed)
        return feed
    }
}
