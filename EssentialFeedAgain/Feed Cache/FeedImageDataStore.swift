//
//  FeedImageDataStore.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

public protocol FeedImageDataStore {
    func retrieve(dataFor url: URL) throws -> Data?
}
