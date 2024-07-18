//
//  CodableFeedStoreTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 18/07/2024.
//

import XCTest
import EssentialFeedAgain

final class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map(\.local)
        }
    }
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date)? {
        guard let data = try? Data(contentsOf: storeURL) else {
            return nil
        }
        
        let cache = try JSONDecoder().decode(Cache.self, from: data)
        return (cache.localFeed, cache.timestamp)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        let encoded = try JSONEncoder().encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
        try encoded.write(to: storeURL)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func tearDown() async throws {
        try await super.tearDown()
        
        removeAllArtefactsAfterTest()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = makeSUT()
        
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        let firstReceived = try await sut.retrieve()
        let secondReceived = try await sut.retrieve()
        
        XCTAssertNil(firstReceived)
        XCTAssertNil(secondReceived)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try await sut.insert(feed, timestamp: timestamp)
        let received = try await sut.retrieve()
        
        XCTAssertEqual(received?.feed, feed)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try await sut.insert(feed, timestamp: timestamp)
        let firstReceived = try await sut.retrieve()
        let secondReceived = try await sut.retrieve()
        
        XCTAssertEqual(firstReceived?.feed, feed)
        XCTAssertEqual(secondReceived?.feed, feed)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() async {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThrowsError(_ = try await sut.retrieve())
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnFailure() async {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThrowsError(_ = try await sut.retrieve())
        await assertThrowsError(_ = try await sut.retrieve())
    }
    
    // MARK: - Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func removeAllArtefactsAfterTest() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appending(path: "\(type(of: self)).store")
    }
}
