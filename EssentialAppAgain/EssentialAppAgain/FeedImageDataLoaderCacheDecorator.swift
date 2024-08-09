//
//  FeedImageDataLoaderCacheDecorator.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 09/08/2024.
//

import Foundation
import EssentialFeedAgain

public final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache
    
    public init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func loadImageData(from url: URL) async throws -> Data {
        let data = try await decoratee.loadImageData(from: url)
        try? await cache.save(data, for: url)
        return data
    }
}
