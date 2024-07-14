//
//  LoadFeedFromRemoteUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 29/04/2024.
//

import XCTest
import EssentialFeedAgain

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsFromURL() async throws {
        let url = URL(string: "http://request-url.com")!
        let (sut, client) = makeSUT(url: url, stubs: [
            success(withStatusCode: 200)
        ])
        
        _ = try await sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversConnectivityErrorOnClientError() async {
        let (sut, _) = makeSUT(stubs: [
            failure(.connectivity)
        ])
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as? RemoteFeedLoaderError, .connectivity)
        }
    }
    
    func test_load_deliversInvalidDataErrorOnNon200HTTPResponses() async {
        let samples = [199, 201, 300, 400, 500]
        let (sut, _) = makeSUT(stubs: samples.map { success(withStatusCode: $0) })
        
        for statusCode in samples {
            await assertThrowsError(_ = try await sut.load(), "Failed on statusCode: \(statusCode)") { error in
                XCTAssertEqual(error as? RemoteFeedLoaderError, .invalidData)
            }
        }
    }
    
    func test_load_deliversInvalidDataErrorOn200ResponseWithInvalidData() async {
        let invalidData = Data("invalid data".utf8)
        let (sut, _) = makeSUT(stubs: [
            success(withStatusCode: 200, data: invalidData)
        ])
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as? RemoteFeedLoaderError, .invalidData)
        }
    }
    
    func test_load_deliversInvalidDataErrorOn200ResponseWithEmptyData() async {
        let emptyData = Data()
        let (sut, _) = makeSUT(stubs: [
            success(withStatusCode: 200, data: emptyData)
        ])
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as? RemoteFeedLoaderError, .invalidData)
        }
    }
    
    func test_load_deliversEmptyFeedOn200ResponseWithEmptyFeedData() async throws {
        let (sut, _) = makeSUT(stubs: [
            success(withStatusCode: 200, data: emptyFeedData())
        ])
        
        let receivedFeed = try await sut.load()
        
        XCTAssertTrue(receivedFeed.isEmpty)
    }
    
    func test_load_deliversFeedOn200ResponseWithFeedData() async throws {
        let expectedFeed = [
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
        let (sut, _) = makeSUT(stubs: [
            success(withStatusCode: 200, data: expectedFeed.toJSONData())
        ])
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, expectedFeed)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = anyURL(),
                         stubs: [HTTPClientSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy(stubs: stubs)
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func success(withStatusCode statusCode: Int) -> HTTPClientSpy.Stub {
        success(withStatusCode: statusCode, data: emptyFeedData())
    }
    
    private func success(withStatusCode statusCode: Int, data: Data) -> HTTPClientSpy.Stub {
        .success((data, HTTPURLResponse(statusCode: statusCode)))
    }
    
    private func failure(_ error: RemoteFeedLoaderError) -> HTTPClientSpy.Stub {
        .failure(error)
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
    typealias JSON = [String: Any]
    
    func toJSONData() -> Data {
        let items: [JSON] = map {
            [
                "id": $0.id.uuidString,
                "description": $0.description as Any,
                "location": $0.location as Any,
                "image": $0.url.absoluteString
            ]
            .compactMapValues { $0 }
        }
        let json: JSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
