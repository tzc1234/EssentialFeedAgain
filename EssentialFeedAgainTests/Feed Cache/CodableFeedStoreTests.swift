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
        
        let cached = try JSONDecoder().decode(Cache.self, from: data)
        return (cached.localFeed, cached.timestamp)
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
        let lastReceived = try await sut.retrieve()
        
        XCTAssertNil(firstReceived)
        XCTAssertNil(lastReceived)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValue() async throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try await sut.insert(feed, timestamp: timestamp)
        let received = try await sut.retrieve()
        
        XCTAssertEqual(received?.feed, feed)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "image-feed.store")
    }
    
    private func removeAllArtefactsAfterTest() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}