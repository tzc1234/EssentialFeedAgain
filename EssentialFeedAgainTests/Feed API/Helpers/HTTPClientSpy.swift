//
//  HTTPClientSpy.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 30/04/2024.
//

import Foundation
import EssentialFeedAgain

final class HTTPClientSpy: HTTPClient {
    private var messages = [(url: URL, completion: Completion)]()
    var requestedURLs: [URL] {
        messages.map(\.url)
    }
    
    private struct Task: HTTPClientTask {
        let afterCancel: () -> Void
        
        func cancel() {
            afterCancel()
        }
    }
    
    private(set) var cancelCallCount = 0
    
    func get(from url: URL, completion: @escaping Completion) -> HTTPClientTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelCallCount += 1
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
        messages[index].completion(.success((data, HTTPURLResponse(statusCode: statusCode))))
    }
}
