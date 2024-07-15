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
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        
        try? await sut.save(feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() async throws {
        let timestamp = Date()
        let (sut, store) = makeSUT(
            currentDate: { timestamp },
            deletionStubs: [.success(())],
            insertionStubs: [.success(())]
        )
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        
        try await sut.save(feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed, .insert(feed, timestamp)])
    }
    
    func test_save_failsOnDeletionError() async {
        let deletionError = anyNSError()
        let (sut, _) = makeSUT(deletionStubs: [.failure(deletionError)])
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        
        await assertThrowsError(try await sut.save(feed))
    }
    
    func test_save_failsOnInsertionError() async {
        let insertionError = anyNSError()
        let (sut, _) = makeSUT(
            deletionStubs: [.success(())],
            insertionStubs: [.failure(insertionError)]
        )
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        
        await assertThrowsError(try await sut.save(feed))
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() async {
        let (sut, _) = makeSUT(
            deletionStubs: [.success(())],
            insertionStubs: [.success(())]
        )
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        
        await assertNoThrow(try await sut.save(feed))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         deletionStubs: [FeedStoreSpy.DeletionStub] = [],
                         insertionStubs: [FeedStoreSpy.InsertionStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy(deletionStubs: deletionStubs, insertionStubs: insertionStubs)
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueFeedImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}
