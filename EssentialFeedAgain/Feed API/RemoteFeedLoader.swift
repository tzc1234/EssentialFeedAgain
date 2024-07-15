//
//  RemoteFeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public enum RemoteFeedLoaderError: Error {
    case connectivity
    case invalidData
}

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() async throws -> [FeedImage] {
        guard let (data, response) = try? await client.get(from: url) else {
            throw RemoteFeedLoaderError.connectivity
        }
        
        let feed = try RemoteFeedImageMapper.map(from: data, response: response)
        return feed.model
    }
}

extension [RemoteFeedImage] {
    var model: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
