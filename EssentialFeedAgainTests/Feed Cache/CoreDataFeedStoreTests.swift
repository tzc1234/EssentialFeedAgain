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
        let sut = try makeSUT()
        
        try await assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        try await assertThatRetrieveTwiceHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        try await assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieveTwice_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        try await assertThatRetrieveTwiceHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        try await assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = try makeSUT()
        
        try await assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() async throws {
        
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> FeedStore {
        let sut = try CoreDataFeedStore(storeURL: URL(filePath: "/dev/null"))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
