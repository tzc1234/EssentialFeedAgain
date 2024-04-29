//
//  FeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

protocol FeedLoader {
    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) -> FeedLoaderTask
}

public protocol FeedLoaderTask {
    func cancel()
}
