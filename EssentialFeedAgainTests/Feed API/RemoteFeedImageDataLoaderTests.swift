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
    
    func loadImageData(from url: URL) async {
        _ = try? await client.get(from: url)
    }
}

final class RemoteFeedImageDataLoaderTests: XCTestCase {
    func test_init_doseNotPerformURLRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadImageData_requestsDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT()
        
        await sut.loadImageData(from: url)
        
        XCTAssertEqual(client.requestedURLs, [url])
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
