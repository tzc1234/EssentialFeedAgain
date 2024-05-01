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
    
    private struct Wrapper: HTTPClientTask {
        let task: URLSessionTask
        
        func cancel() {
            task.cancel()
        }
    }
    
    public func get(from url: URL, completion: @escaping Completion) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let data, let httpResponse = response as? HTTPURLResponse {
                completion(.success((data, httpResponse)))
            } else if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedRepresentationError()))
            }
        }
        task.resume()
        return Wrapper(task: task)
    }
}
