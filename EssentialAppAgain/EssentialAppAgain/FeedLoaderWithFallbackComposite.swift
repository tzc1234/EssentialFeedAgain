//
//  FeedLoaderWithFallbackComposite.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 07/08/2024.
//

import EssentialFeedAgain

public final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader
    
    public init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func load() async throws -> [FeedImage] {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()
        }
    }
}
