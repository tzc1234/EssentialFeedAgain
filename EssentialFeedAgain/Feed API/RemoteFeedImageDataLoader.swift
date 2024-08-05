//
//  RemoteFeedImageDataLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 05/08/2024.
//

import Foundation

public final class RemoteFeedImageDataLoader {
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public func loadImageData(from url: URL) async throws -> Data {
        let (data, response) = try await client.get(from: url)
        guard response.statusCode == 200, !data.isEmpty else {
            throw Error.invalidData
        }
        
        return data
    }
}
