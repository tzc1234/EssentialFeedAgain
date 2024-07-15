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
    
    func save(_ feed: [FeedImage]) async {
        await store.deleteCachedFeed()
    }
}

final class FeedStore {
    enum Message {
        case deleteCachedFeed
    }
    
    private(set) var messages = [Message]()
    
    func deleteCachedFeed() async {
        messages.append(.deleteCachedFeed)
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyStoreUponInit() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_save_requestsCacheDeletion() async {
        let (sut, store) = makeSUT()
        let feed = [uniqueImage(), uniqueImage()]
        
        await sut.save(feed)
        
        XCTAssertEqual(store.messages, [.deleteCachedFeed])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, 
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}
