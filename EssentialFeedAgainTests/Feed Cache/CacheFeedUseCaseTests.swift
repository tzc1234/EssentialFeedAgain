//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 15/07/2024.
//

import XCTest

final class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}

final class FeedStore {
    private(set) var messages = [Any]()
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyStoreUponInit() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertTrue(store.messages.isEmpty)
    }
}
