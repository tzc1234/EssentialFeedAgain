//
//  RemoteFeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public enum RemoteFeedLoaderError: Error {
    case connectivity
    case invalidData
}

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    private struct Wrapper: FeedLoaderTask {
        let task: HTTPClientTask
        
        func cancel() {
            task.cancel()
        }
    }
    
    public func load(completion: @escaping Completion) -> FeedLoaderTask {
        Wrapper(task: client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                do {
                    let feed = try RemoteFeedImageMapper.map(from: data, response: response)
                    completion(.success(feed.model))
                } catch {
                    completion(.failure(error))
                }
            case .failure:
                completion(.failure(RemoteFeedLoaderError.connectivity))
            }
        })
    }
}

extension [RemoteFeedImage] {
    var model: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
