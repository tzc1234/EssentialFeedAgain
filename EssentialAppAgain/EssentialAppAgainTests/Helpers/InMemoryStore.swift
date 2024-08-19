//
//  InMemoryStore.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 19/08/2024.
//

import Foundation
import EssentialFeedAgain

final class InMemoryStore {
    typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)
    
    private(set) var feedCache: CachedFeed?
    private var feedImageDataCache = [URL: Data]()
    
    init(feedCache: CachedFeed? = nil) {
        self.feedCache = feedCache
    }
}

extension InMemoryStore: FeedStore {
    func retrieve() async throws -> CachedFeed? {
        feedCache
    }
    
    @MainActor
    func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        feedCache = (feed, timestamp)
    }
    
    @MainActor
    func deleteCachedFeed() async throws {
        feedCache = nil
    }
}
    
extension InMemoryStore: FeedImageDataStore {
    @MainActor
    func insert(_ data: Data, for url: URL) async throws {
        feedImageDataCache[url] = data
    }
    
    func retrieve(dataFor url: URL) async throws -> Data? {
        feedImageDataCache[url]
    }
}

extension InMemoryStore {
    static var empty: InMemoryStore {
        InMemoryStore()
    }
    
    static var withExpiredFeedCache: InMemoryStore {
        InMemoryStore(feedCache: ([], .distantPast))
    }
    
    static var withNonExpiredFeedCache: InMemoryStore {
        InMemoryStore(feedCache: ([], .now))
    }
}
