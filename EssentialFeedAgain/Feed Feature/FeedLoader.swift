//
//  FeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public protocol FeedLoader {
    func load() async throws -> [FeedImage]
}
