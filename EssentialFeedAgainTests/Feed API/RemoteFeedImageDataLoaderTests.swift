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
    
    enum Error: Swift.Error {
        case invalidData
    }
    
    func loadImageData(from url: URL) async throws {
        let (_, response) = try await client.get(from: url)
        guard response.statusCode == 200 else {
            throw Error.invalidData
        }
        
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
        
        try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadImageDataTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT()
        
        try? await sut.loadImageData(from: url)
        try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadImageData_deliversErrorOnClientError() async {
        let clientError = NSError(domain: "client error", code: 0)
        let (sut, _) = makeSUT(stubs: [.failure(clientError)])
        
        await assertThrowsError(try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as NSError, clientError)
        }
    }
    
    func test_loadImageData_deliversInvalidDataErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]
        let (sut, _) = makeSUT(stubs: samples.map { successOn(statusCode: $0) })
        
        for statusCode in samples {
            await assertThrowsError(
                try await sut.loadImageData(from: anyURL()),
                "Expected an error on statusCode: \(statusCode)"
            ) { error in
                XCTAssertEqual(error as? RemoteFeedImageDataLoader.Error, .invalidData)
            }
        }
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
    
    private func successOn(statusCode: Int) -> HTTPClientSpy.Stub {
        .success((anyData(), HTTPURLResponse(statusCode: statusCode)))
    }
}
