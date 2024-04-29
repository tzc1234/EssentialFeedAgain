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
                client.complete(withStatusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_deliversInvalidDataErrorOn200ResponseWithInvalidData() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .failure(.invalidData), when: {
            let invalidData = Data("invalid data".utf8)
            client.complete(with: invalidData)
        })
    }
    
    func test_load_deliversInvalidDataErrorOn200ResponseWithEmptyData() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .failure(.invalidData), when: {
            let emptyData = Data()
            client.complete(with: emptyData)
        })
    }
    
    func test_load_deliversEmptyFeedWhenReceivedEmptyFeedData() {
        let (sut, client) = makeSUT()
        
        expect(sut, withExpected: .success([]), when: {
            let emptyFeedData = Data("{\"items\":[]}".utf8)
            client.complete(with: emptyFeedData)
        })
    }
    
    func test_load_deliversOneFeedWhenReceivedOneFeedData() {
        let (sut, client) = makeSUT()
        let feed = [
            makeFeedImage(
                description: "a description",
                location: "a location",
                url: URL(string: "https://a-url.com")!
            )
        ]
        
        expect(sut, withExpected: .success(feed), when: {
            client.complete(with: feed.toData())
        })
    }
    
    func test_load_deliversFeedWhenReceivedFeedData() {
        let (sut, client) = makeSUT()
        let feed = [
            makeFeedImage(
                description: "a description",
                url: URL(string: "https://a-url.com")!
            ),
            makeFeedImage(
                location: "a location",
                url: URL(string: "https://another-url.com")!
            ),
            makeFeedImage()
        ]
        
        expect(sut, withExpected: .success(feed), when: {
            client.complete(with: feed.toData())
        })
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
                         line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, 
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
    
    private func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }
    
    private final class HTTPClientSpy: HTTPClient {
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
        
        func complete(withStatusCode statusCode: Int, at index: Int = 0) {
            messages[index].completion(.success((Data(), HTTPURLResponse(statusCode: statusCode))))
        }
        
        func complete(with data: Data, at index: Int = 0) {
            messages[index].completion(.success((data, HTTPURLResponse(statusCode: 200))))
        }
    }
}

private extension [FeedImage] {
    func toData() -> Data {
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
