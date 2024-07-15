//
//  FeedStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 15/07/2024.
//

import Foundation

public protocol FeedStore {
    func deleteCachedFeed() async throws
    func insert(_ feed: [FeedImage], timestamp: Date) async throws
}
