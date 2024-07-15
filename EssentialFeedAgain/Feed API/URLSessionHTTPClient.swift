//
//  URLSessionHTTPClient.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 30/04/2024.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public struct UnexpectedRepresentationError: Error {}
    
    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnexpectedRepresentationError()
        }
        
        return (data, httpResponse)
    }
}
