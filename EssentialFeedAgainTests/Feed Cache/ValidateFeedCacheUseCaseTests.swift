//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 16/07/2024.
//

import XCTest
import EssentialFeedAgain

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyStoreUponInit() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() async throws {
        let (sut, store) = makeSUT(
            deletionStubs: [.success(())],
            retrievalStubs: [.failure(anyNSError())]
        )
        
        try await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() async throws {
        let emptyCache = [LocalFeedImage]()
        let (sut, store) = makeSUT(retrievalStubs: [success(with: emptyCache, timestamp: .now)])
        
        try await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteOnNonExpiredCache() async throws {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date.now
        let nonExpiredTimestamp = fixCurrentDate.minusMaxCacheAgeInDays().adding(seconds: 1)
        let (sut, store) = makeSUT(
            currentDate: { fixCurrentDate },
            retrievalStubs: [success(with: feed.local, timestamp: nonExpiredTimestamp)]
        )
        
        try await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve])
    }
    
    func test_validateCache_deletesOnExpirationCache() async throws {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date.now
        let expirationTimestamp = fixCurrentDate.minusMaxCacheAgeInDays()
        let (sut, store) = makeSUT(
            currentDate: { fixCurrentDate },
            deletionStubs: [.success(())],
            retrievalStubs: [success(with: feed.local, timestamp: expirationTimestamp)]
        )
        
        try await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesOnExpiredCache() async throws {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date.now
        let expiredTimestamp = fixCurrentDate.minusMaxCacheAgeInDays().adding(seconds: -1)
        let (sut, store) = makeSUT(
            currentDate: { fixCurrentDate },
            deletionStubs: [.success(())],
            retrievalStubs: [success(with: feed.local, timestamp: expiredTimestamp)]
        )
        
        try await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_failsOnDeletionErrorOfFailedRetrieval() async {
        let (sut, store) = makeSUT(
            deletionStubs: [.failure(anyNSError())],
            retrievalStubs: [.failure(anyNSError())]
        )
        
        await assertThrowsError(try await sut.validateCache())
    }
    
    func test_validateCache_succeedsOnSuccessfulDeletionOfFailedRetrieval() async {
        let (sut, store) = makeSUT(
            deletionStubs: [.success(())],
            retrievalStubs: [.failure(anyNSError())]
        )
        
        await assertNoThrow(try await sut.validateCache())
    }

    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         deletionStubs: [FeedStoreSpy.DeletionStub] = [],
                         retrievalStubs: [FeedStoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy(
            deletionStubs: deletionStubs,
            insertionStubs: [],
            retrievalStubs: retrievalStubs
        )
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func success(with feed: [LocalFeedImage], timestamp: Date) -> FeedStoreSpy.RetrieveStub {
        .success((feed, timestamp))
    }
}
