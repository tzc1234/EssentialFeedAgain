//
//  FeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public protocol FeedLoader {
    typealias Completion = (Result<[FeedImage], Error>) -> Void
    
    func load(completion: @escaping Completion) -> FeedLoaderTask
}

public protocol FeedLoaderTask {
    func cancel()
}
