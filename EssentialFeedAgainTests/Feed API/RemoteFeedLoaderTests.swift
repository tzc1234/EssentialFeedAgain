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
        
        _ = sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .failure(.connectivity), when: {
            client.complete(with: anyNSError())
        })
    }
    
    func test_load_deliversInvalidDataErrorOnNon200HTTPResponses() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, statusCode in
            expect(sut, withExpected: .failure(.invalidData), when: {
                let validData = emptyFeedData()
                client.complete(withStatusCode: statusCode, data: validData, at: index)
            })
        }
    }
    
    func test_load_deliversInvalidDataErrorOn200ResponseWithInvalidData() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .failure(.invalidData), when: {
            let invalidData = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidData)
        })
    }
    
    func test_load_deliversInvalidDataErrorOn200ResponseWithEmptyData() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .failure(.invalidData), when: {
            let emptyData = Data()
            client.complete(withStatusCode: 200, data: emptyData)
        })
    }
    
    func test_load_deliversEmptyFeedOn200ResponseWithEmptyFeedData() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .success([]), when: {
            client.complete(withStatusCode: 200, data: emptyFeedData())
        })
    }
    
    func test_load_deliversFeedOn200ResponseWithFeedData() {
        let (sut, client) = makeSUT()
        let feed = [
            makeFeedImage(
                description: "a description",
                location: "a location",
                url: URL(string: "https://a-url.com")!
            ),
            makeFeedImage(
                description: "another description",
                url: URL(string: "https://another-url.com")!
            ),
            makeFeedImage(
                location: "another location",
                url: URL(string: "https://another-different-url.com")!
            ),
            makeFeedImage()
        ]
        
        expect(sut, withExpected: .success(feed), when: {
            client.complete(withStatusCode: 200, data: feed.toJSONData())
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceIsDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: anyURL(), client: client)
        
        var completionCount = 0
        _ = sut?.load { _ in completionCount += 1 }
        
        sut = nil
        client.complete(withStatusCode: 200, data: emptyFeedData())
        
        XCTAssertEqual(completionCount, 0)
    }
    
    func test_cancelTask_cancelsClientTask() {
        let (sut, client) = makeSUT()
        
        let task = sut.load { _ in }
        task.cancel()
        
        XCTAssertEqual(client.cancelCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = anyURL(),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: FeedLoader,
                        withExpected expectedResult: Result<[FeedImage], RemoteFeedLoaderError>,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        _ = sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as? RemoteFeedLoaderError, expectedError, file: file, line: line)
            default:
                XCTFail("Expect result: \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1)
    }
    
    private func makeFeedImage(id: UUID = UUID(),
                               description: String? = nil,
                               location: String? = nil, 
                               url: URL = anyURL()) -> FeedImage {
        FeedImage(id: id, description: description, location: location, url: url)
    }
    
    private func emptyFeedData() -> Data {
        Data("{\"items\":[]}".utf8)
    }
}

private extension [FeedImage] {
    func toJSONData() -> Data {
        let images = map {
            [
                "id": $0.id.uuidString,
                "description": $0.description as Any,
                "location": $0.location as Any,
                "image": $0.url.absoluteString
            ].compactMapValues { $0 } as [String: Any]
        }
        let json: [String: Any] = ["items": images]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
