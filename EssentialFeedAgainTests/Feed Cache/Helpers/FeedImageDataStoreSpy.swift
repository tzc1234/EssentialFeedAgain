//
//  FeedImageDataStoreSpy.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation
import EssentialFeedAgain

final class FeedImageDataStoreSpy: FeedImageDataStore {
    typealias RetrieveStub = Result<Data?, Error>
    typealias InsertStub = Result<Void, Error>
    
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(Data, for: URL)
    }
    
    private(set) var messages = [Message]()
    private var retrieveStubs = [RetrieveStub]()
    private var insertStubs = [InsertStub]()
    
    init(retrieveStubs: [RetrieveStub], insertStubs: [InsertStub]) {
        self.retrieveStubs = retrieveStubs
        self.insertStubs = insertStubs
    }
    
    func retrieve(dataFor url: URL) throws -> Data? {
        messages.append(.retrieve(dataFor: url))
        
        guard !retrieveStubs.isEmpty else { return nil }
        
        return try retrieveStubs.removeFirst().get()
    }
    
    func insert(_ data: Data, for url: URL) throws {
        messages.append(.insert(data, for: url))
        
        guard !insertStubs.isEmpty else { return }
        
        try insertStubs.removeFirst().get()
    }
}
