//
//  RemoteFeedImageDataLoaderTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 05/08/2024.
//

import XCTest
import EssentialFeedAgain

final class RemoteFeedImageDataLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
}

final class RemoteFeedImageDataLoaderTests: XCTestCase {
    func test_init_doseNotPerformURLRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stubs: [HTTPClientSpy.Stub] = [], 
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteFeedImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy(stubs: stubs)
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
}
