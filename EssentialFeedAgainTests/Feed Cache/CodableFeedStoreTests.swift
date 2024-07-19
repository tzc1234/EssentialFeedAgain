//
//  CodableFeedStoreTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 18/07/2024.
//

import XCTest
import EssentialFeedAgain

final class CodableFeedStoreTests: XCTestCase, FailableFeedStore {
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
    
    func test_retrieve_deliversErrorOnRetrievalError() async {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThrowsError(_ = try await sut.retrieve())
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnRetrievalError() async {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThrowsError(_ = try await sut.retrieve())
        await assertThrowsError(_ = try await sut.retrieve())
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertNoThrow(try await sut.insert(uniqueImageFeed().local, timestamp: .now))
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = makeSUT()
        
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        
        let lastFeed = uniqueImageFeed().local
        let lastTimestamp = Date.now
        await assertNoThrow(try await sut.insert(lastFeed, timestamp: lastTimestamp))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = makeSUT()
        
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        
        let lastFeed = uniqueImageFeed().local
        let lastTimestamp = Date.now
        try await sut.insert(lastFeed, timestamp: lastTimestamp)
        
        let received = try await sut.retrieve()
        
        XCTAssertEqual(received?.feed, lastFeed)
        XCTAssertEqual(received?.timestamp, lastTimestamp)
    }
    
    func test_insert_deliversErrorOnInsertionError() async {
        let invalidStoreURL = URL(string: "invalid:\\store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        await assertThrowsError(try await sut.insert(feed, timestamp: timestamp))
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() async throws {
        let invalidStoreURL = URL(string: "invalid:\\store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try? await sut.insert(feed, timestamp: timestamp)
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertNoThrow(try await sut.deleteCachedFeed())
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await sut.deleteCachedFeed()
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = makeSUT()
        
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        
        await assertNoThrow(try await sut.deleteCachedFeed())
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = makeSUT()
        
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        try await sut.deleteCachedFeed()
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
    
    func test_delete_deliversErrorOnDeletionError() async {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        await assertThrowsError(try await sut.deleteCachedFeed())
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() async throws {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        try? await sut.deleteCachedFeed()
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func removeAllArtefactsAfterTest() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appending(path: "\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
