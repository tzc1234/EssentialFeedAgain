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
        await store.insert(feed, timestamp: currentDate())
    }
}

final class FeedStore {
    typealias DeletionStub = Result<Void, Error>
    
    enum Message: Equatable {
        case deletion
        case insertion([FeedImage], Date)
    }
    
    private(set) var messages = [Message]()
    
    private var deletionStubs: [DeletionStub]
    
    init(deletionStubs: [DeletionStub]) {
        self.deletionStubs = deletionStubs
    }
    
    func deleteCachedFeed() async throws {
        messages.append(.deletion)
        try deletionStubs.removeFirst().get()
    }
    
    func insert(_ feed: [FeedImage], timestamp: Date) async {
        messages.append(.insertion(feed, timestamp))
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
        let feed = [uniqueImage(), uniqueImage()]
        
        await assertThrowsError(try await sut.save(feed))
        
        XCTAssertEqual(store.messages, [.deletion])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() async throws {
        let timestamp = Date()
        let (sut, store) = makeSUT(
            currentDate: { timestamp },
            deletionStubs: [.success(())]
        )
        let feed = [uniqueImage(), uniqueImage()]
        
        try await sut.save(feed)
        
        XCTAssertEqual(store.messages, [.deletion, .insertion(feed, timestamp)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         deletionStubs: [FeedStore.DeletionStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore(deletionStubs: deletionStubs)
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}
