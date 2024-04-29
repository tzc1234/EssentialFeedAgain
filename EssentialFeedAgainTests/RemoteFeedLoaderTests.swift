//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 29/04/2024.
//

import XCTest

final class RemoteFeedLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
}

protocol HTTPClient {
    
}

final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs = [URL]()
}

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
}
