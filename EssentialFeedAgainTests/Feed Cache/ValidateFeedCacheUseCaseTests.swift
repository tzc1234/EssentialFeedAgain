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
    
    func test_validate_deletesCacheOnRetrievalError() async {
        let (sut, store) = makeSUT(
            deletionStubs: [.success(())],
            retrievalStubs: [.failure(anyNSError())]
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
}
