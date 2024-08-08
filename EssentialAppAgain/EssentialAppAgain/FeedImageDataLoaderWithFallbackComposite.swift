//
//  FeedImageDataLoaderWithFallbackComposite.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 08/08/2024.
//

import Foundation
import EssentialFeedAgain

public final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader
    
    public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func loadImageData(from url: URL) async throws -> Data {
        do {
            return try await primary.loadImageData(from: url)
        } catch {
            return try await fallback.loadImageData(from: url)
        }
    }
}
