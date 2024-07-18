//
//  FeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 15/07/2024.
//

import Foundation

public protocol FeedStore {
    func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date)?
    func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws
    func deleteCachedFeed() async throws
}
