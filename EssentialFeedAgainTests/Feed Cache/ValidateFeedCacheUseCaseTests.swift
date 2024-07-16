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
    
    func test_validateCache_deletesCacheOnRetrievalError() async {
        let (sut, store) = makeSUT(
            deletionStubs: [.success(())],
            retrievalStubs: [.failure(anyNSError())]
        )
        
        await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() async {
        let emptyCache = [LocalFeedImage]()
        let (sut, store) = makeSUT(retrievalStubs: [success(with: emptyCache, timestamp: .now)])
        
        await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteOnNonExpiredCache() async {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date.now
        let nonExpiredTimestamp = fixCurrentDate.minusMaxCacheAgeInDays().adding(seconds: 1)
        let (sut, store) = makeSUT(
            currentDate: { fixCurrentDate },
            retrievalStubs: [success(with: feed.local, timestamp: nonExpiredTimestamp)]
        )
        
        await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve])
    }
    
    func test_validateCache_deletesOnExpirationCache() async {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date.now
        let expirationTimestamp = fixCurrentDate.minusMaxCacheAgeInDays()
        let (sut, store) = makeSUT(
            currentDate: { fixCurrentDate },
            deletionStubs: [.success(())],
            retrievalStubs: [success(with: feed.local, timestamp: expirationTimestamp)]
        )
        
        await sut.validateCache()
        
        XCTAssertEqual(store.messages, [.retrieve, .deleteCachedFeed])
    }

    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         deletionStubs: [FeedStoreSpy.DeletionStub] = [],
                         insertionStubs: [FeedStoreSpy.InsertionStub] = [],
                         retrievalStubs: [FeedStoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy(
            deletionStubs: deletionStubs,
            insertionStubs: insertionStubs,
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
