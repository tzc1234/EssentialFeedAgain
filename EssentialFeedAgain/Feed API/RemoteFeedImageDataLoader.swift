//
//  RemoteFeedImageDataLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 05/08/2024.
//

import Foundation

public final class RemoteFeedImageDataLoader: FeedImageDataLoader {
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public func loadImageData(from url: URL) async throws -> Data {
        guard let (data, response) = try? await client.get(from: url) else {
            throw Error.connectivity
        }
        
        guard isOK(response), !data.isEmpty else {
            throw Error.invalidData
        }
        
        return data
    }
    
    private func isOK(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 200
    }
}
