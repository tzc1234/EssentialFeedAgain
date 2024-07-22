//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 22/07/2024.
//

import XCTest
import EssentialFeedAgain

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = makeSUT()
        
        try await assertThatRetrieveTwiceHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnNonEmptyCache() async throws {
        
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() async {
        
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() async throws {
        
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() async throws {
        
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() async {
        
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() async throws {
        
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
