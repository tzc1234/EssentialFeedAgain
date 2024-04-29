//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 29/04/2024.
//

import XCTest

final class RemoteFeedLoader {
    private let client: HTTPClientSpy
    
    init(client: HTTPClientSpy) {
        self.client = client
    }
    
    func load(for url: URL) {
        client.get(from: url)
    }
}

final class HTTPClientSpy {
    private(set) var requestedURLs = [URL]()
    
    func get(from url: URL) {
        requestedURLs.append(url)
    }
}

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsFromURL() {
        let (sut, client) = makeSUT()
        let url = URL(string: "http://request-url.com")!
        
        sut.load(for: url)
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
}
