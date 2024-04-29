//
//  RemoteFeedLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

struct RemoteFeedImage: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

extension [RemoteFeedImage] {
    var model: [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}

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
    
    private struct Root: Decodable {
        let items: [RemoteFeedImage]
    }
    
    public func load(completion: @escaping (Result<[FeedImage], Swift.Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
                    return completion(.failure(Error.invalidData))
                }
                
                return completion(.success(root.items.model))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}

public protocol HTTPClient {
    typealias Completion = (Result<(Data, HTTPURLResponse), Error>) -> Void
    
    func get(from url: URL, completion: @escaping Completion)
}
