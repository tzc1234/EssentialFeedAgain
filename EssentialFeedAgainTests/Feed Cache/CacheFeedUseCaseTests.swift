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
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ feed: [FeedImage]) async throws {
        try await store.deleteCachedFeed()
        await store.insert(feed)
    }
}

final class FeedStore {
    typealias DeletionStub = Result<Void, Error>
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insertion([FeedImage])
    }
    
    private(set) var messages = [Message]()
    
    private var deletionStubs: [DeletionStub]
    
    init(deletionStubs: [DeletionStub]) {
        self.deletionStubs = deletionStubs
    }
    
    func deleteCachedFeed() async throws {
        messages.append(.deleteCachedFeed)
        try deletionStubs.removeFirst().get()
    }
    
    func insert(_ feed: [FeedImage]) async {
        messages.append(.insertion(feed))
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyStoreUponInit() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_save_requestsCacheDeletion() async throws {
        let (sut, store) = makeSUT()
        let feed = [uniqueImage(), uniqueImage()]
        
        try await sut.save(feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed, .insertion(feed)])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() async {
        let deletionError = anyNSError()
        let (sut, store) = makeSUT(deletionStubs: [.failure(deletionError)])
        let feed = [uniqueImage(), uniqueImage()]
        
        await assertThrowsError(try await sut.save(feed))
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionOnSuccessfulDeletion() async throws {
        let (sut, store) = makeSUT(deletionStubs: [.success(())])
        let feed = [uniqueImage(), uniqueImage()]
        
        try await sut.save(feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed, .insertion(feed)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(deletionStubs: [FeedStore.DeletionStub] = [.success(())],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore(deletionStubs: deletionStubs)
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}
