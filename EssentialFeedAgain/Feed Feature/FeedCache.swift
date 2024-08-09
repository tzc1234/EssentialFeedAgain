//
//  FeedCache.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 09/08/2024.
//

import Foundation

public protocol FeedCache {
    func save(_ feed: [FeedImage]) async throws
}
