//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 29/04/2024.
//

import XCTest
import EssentialFeedAgain

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsFromURL() {
        let url = URL(string: "http://request-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .failure(.connectivity), when: {
            client.complete(with: anyNSError())
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponses() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, statusCode in
            expect(sut, withExpected: .failure(.invalidData), when: {
                client.complete(withStatusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200ResponseWithInvalidData() {
        let (sut, client) = makeSUT()
        let invalidData = Data("invalid data".utf8)
        
        expect(sut, withExpected: .failure(.invalidData), when: {
            client.complete(with: invalidData)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = anyURL(),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, 
                        withExpected expectedResult: Result<[FeedImage], RemoteFeedLoader.Error>,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success):
                XCTFail("Should be a failure", file: file, line: line)
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as? RemoteFeedLoader.Error, expectedError, file: file, line: line)
            default:
                XCTFail("Expect result: \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }
    
    private final class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: Completion)]()
        var requestedURLs: [URL] {
            messages.map(\.url)
        }
        
        func get(from url: URL, completion: @escaping Completion) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, at index: Int = 0) {
            messages[index].completion(.success((Data(), HTTPURLResponse(statusCode: statusCode))))
        }
        
        func complete(with data: Data, at index: Int = 0) {
            messages[index].completion(.success((data, HTTPURLResponse(statusCode: 200))))
        }
    }
}
