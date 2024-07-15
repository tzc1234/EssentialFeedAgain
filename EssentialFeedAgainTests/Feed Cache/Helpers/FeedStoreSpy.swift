//
//  FeedStoreSpy.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 15/07/2024.
//

import Foundation
import EssentialFeedAgain

final class FeedStoreSpy: FeedStore {
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
