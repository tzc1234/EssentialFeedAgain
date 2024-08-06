//
//  CoreDataFeedStore+FeedImageDataStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(_ data: Data, for url: URL) async throws {
        try await perform { context in
            guard let image = try ManagedFeedImage.first(for: url, in: context) else { return }
            
            image.data = data
            try context.save()
        }
    }
    
    public func retrieve(dataFor url: URL) async throws -> Data? {
        try await perform { context in
            guard let image = try ManagedFeedImage.first(for: url, in: context) else {
                return nil
            }
            
            return image.data
        }
    }
}
