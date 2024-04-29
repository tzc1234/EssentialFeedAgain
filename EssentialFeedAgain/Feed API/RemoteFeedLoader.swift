//
//  RemoteFeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public func load(completion: @escaping (Result<[FeedImage], Swift.Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((_, response)):
                guard response.statusCode == 200 else {
                    return completion(.failure(Error.invalidData))
                }
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}

public protocol HTTPClient {
    typealias Completion = (Result<(Void, HTTPURLResponse), Error>) -> Void
    
    func get(from url: URL, completion: @escaping Completion)
}
