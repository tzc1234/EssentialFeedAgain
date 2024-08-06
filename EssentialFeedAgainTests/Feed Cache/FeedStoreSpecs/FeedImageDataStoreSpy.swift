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
    
    enum Message: Equatable {
        case retrieve(dataFor: URL)
    }
    
    private(set) var messages = [Message]()
    private var retrieveStubs = [RetrieveStub]()
    
    init(retrieveStubs: [RetrieveStub]) {
        self.retrieveStubs = retrieveStubs
    }
    
    func retrieve(dataFor url: URL) throws -> Data? {
        messages.append(.retrieve(dataFor: url))
        
        guard !retrieveStubs.isEmpty else { return nil }
        
        return try retrieveStubs.removeFirst().get()
    }
}
