//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 15/07/2024.
//

import XCTest
import EssentialFeedAgain

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyStoreUponInit() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() async {
        let deletionError = anyNSError()
        let (sut, store) = makeSUT(deletionStubs: [.failure(deletionError)])
        
        try? await sut.save(uniqueImageFeed().models)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() async throws {
        let timestamp = Date()
        let (sut, store) = makeSUT(
            currentDate: { timestamp },
            deletionStubs: [.success(())],
            insertionStubs: [.success(())]
        )
        let feed = uniqueImageFeed()
        
        try await sut.save(feed.models)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }
    
    func test_save_failsOnDeletionError() async {
        let deletionError = anyNSError()
        let (sut, _) = makeSUT(deletionStubs: [.failure(deletionError)])
        
        await assertThrowsError(try await sut.save(uniqueImageFeed().models)) { error in
            XCTAssertEqual(error as NSError, deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() async {
        let insertionError = anyNSError()
        let (sut, _) = makeSUT(
            deletionStubs: [.success(())],
            insertionStubs: [.failure(insertionError)]
        )
        
        await assertThrowsError(try await sut.save(uniqueImageFeed().models)) { error in
            XCTAssertEqual(error as NSError, insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() async {
        let (sut, _) = makeSUT(
            deletionStubs: [.success(())],
            insertionStubs: [.success(())]
        )
        
        await assertNoThrow(try await sut.save(uniqueImageFeed().models))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         deletionStubs: [FeedStoreSpy.DeletionStub] = [],
                         insertionStubs: [FeedStoreSpy.InsertionStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy(deletionStubs: deletionStubs, insertionStubs: insertionStubs, retrievalStubs: [])
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
