//
//  FeedImageDataStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

public protocol FeedImageDataStore {
    func insert(_ data: Data, for url: URL) async throws
    func retrieve(dataFor url: URL) async throws -> Data?
}
