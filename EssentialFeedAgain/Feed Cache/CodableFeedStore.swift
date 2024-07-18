//
//  CodableFeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 18/07/2024.
//

import Foundation

public final class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map(\.local)
        }
    }
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date)? {
        guard let data = try? Data(contentsOf: storeURL) else {
            return nil
        }
        
        let cache = try JSONDecoder().decode(Cache.self, from: data)
        return (cache.localFeed, cache.timestamp)
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        let encoded = try JSONEncoder().encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
        try encoded.write(to: storeURL)
    }
    
    public func deleteCachedFeed() async throws {
        guard FileManager.default.fileExists(atPath: storeURL.path()) else {
            return
        }
        
        try FileManager.default.removeItem(at: storeURL)
    }
}
