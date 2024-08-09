//
//  FeedImageDataCache.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 09/08/2024.
//

import Foundation

public protocol FeedImageDataCache {
    func save(_ data: Data, for url: URL) async throws
}
