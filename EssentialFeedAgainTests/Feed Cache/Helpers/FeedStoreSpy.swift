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
    typealias RetrieveStub = Result<Void, Error>
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var messages = [Message]()
    
    private var deletionStubs: [DeletionStub]
    private var insertionStubs: [InsertionStub]
    private var retrievalStubs: [InsertionStub]
    
    init(deletionStubs: [DeletionStub], insertionStubs: [InsertionStub], retrievalStubs: [InsertionStub]) {
        self.deletionStubs = deletionStubs
        self.insertionStubs = insertionStubs
        self.retrievalStubs = retrievalStubs
    }
    
    func deleteCachedFeed() async throws {
        messages.append(.deleteCachedFeed)
        try deletionStubs.removeFirst().get()
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
        messages.append(.insert(feed, timestamp))
        try insertionStubs.removeFirst().get()
    }
    
    func retrieve() async throws {
        messages.append(.retrieve)
        try retrievalStubs.removeFirst().get()
    }
}
