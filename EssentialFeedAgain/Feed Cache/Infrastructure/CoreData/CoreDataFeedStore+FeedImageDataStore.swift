//
//  CoreDataFeedStore+FeedImageDataStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(_ data: Data, for url: URL) async throws {
        
    }
    
    public func retrieve(dataFor url: URL) async throws -> Data? {
        return nil
    }
}
