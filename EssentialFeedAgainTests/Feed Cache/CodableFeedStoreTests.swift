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
        
        try await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatRetrieveTwiceHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatRetrieveTwiceHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversErrorOnRetrievalError() async {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThatRetrieveDeliversErrorOnRetrievalError(on: sut)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnRetrievalError() async {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThatRetrieveTwiceHasNoSideEffectsOnRetrievalError(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = makeSUT()
        
        try await assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() async {
        let invalidStoreURL = URL(string: "invalid:\\store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        await assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() async throws {
        let invalidStoreURL = URL(string: "invalid:\\store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        try await assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = makeSUT()
        
        try await assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() async {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        await assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() async throws {
        let noDeletionPermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        try await assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
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
