//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 15/07/2024.
//

import XCTest
import EssentialFeedAgain

final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ feed: [FeedImage]) async throws {
        try await store.deleteCachedFeed()
        try await store.insert(feed, timestamp: currentDate())
    }
}

final class FeedStore {
    typealias DeletionStub = Result<Void, Error>
    typealias InsertionStub = Result<Void, Error>
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([FeedImage], Date)
    }
    
    private(set) var messages = [Message]()
    
    private var deletionStubs: [DeletionStub]
    private var insertionStubs: [InsertionStub]
    
    init(deletionStubs: [DeletionStub], insertionStubs: [InsertionStub]) {
        self.deletionStubs = deletionStubs
        self.insertionStubs = insertionStubs
    }
    
    func deleteCachedFeed() async throws {
        messages.append(.deleteCachedFeed)
        try deletionStubs.removeFirst().get()
    }
    
    func insert(_ feed: [FeedImage], timestamp: Date) async throws {
        messages.append(.insert(feed, timestamp))
        try insertionStubs.removeFirst().get()
    }
}

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
                         deletionStubs: [FeedStore.DeletionStub] = [],
                         insertionStubs: [FeedStore.InsertionStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore(deletionStubs: deletionStubs, insertionStubs: insertionStubs)
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueFeedImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}
