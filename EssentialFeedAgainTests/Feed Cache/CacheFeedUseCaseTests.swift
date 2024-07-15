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
        
        try? await sut.save(uniqueItems().feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() async throws {
        let timestamp = Date()
        let (sut, store) = makeSUT(
            currentDate: { timestamp },
            deletionStubs: [.success(())],
            insertionStubs: [.success(())]
        )
        let items = uniqueItems()
        
        try await sut.save(items.feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed, .insert(items.local, timestamp)])
    }
    
    func test_save_failsOnDeletionError() async {
        let deletionError = anyNSError()
        let (sut, _) = makeSUT(deletionStubs: [.failure(deletionError)])
        
        await assertThrowsError(try await sut.save(uniqueItems().feed))
    }
    
    func test_save_failsOnInsertionError() async {
        let insertionError = anyNSError()
        let (sut, _) = makeSUT(
            deletionStubs: [.success(())],
            insertionStubs: [.failure(insertionError)]
        )
        
        await assertThrowsError(try await sut.save(uniqueItems().feed))
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() async {
        let (sut, _) = makeSUT(
            deletionStubs: [.success(())],
            insertionStubs: [.success(())]
        )
        
        await assertNoThrow(try await sut.save(uniqueItems().feed))
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
    
    private func uniqueItems() -> (feed: [FeedImage], local: [LocalFeedImage]) {
        let feed = [uniqueFeedImage(), uniqueFeedImage()]
        let localFeed = feed.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (feed, localFeed)
    }
    
    private func uniqueFeedImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}
