//
//  FeedLoaderStub.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 09/08/2024.
//

import EssentialFeedAgain

final class FeedLoaderStub: FeedLoader {
    typealias FeedStub = Result<[FeedImage], Error>
    
    private var stub: FeedStub
    
    init(stub: FeedStub) {
        self.stub = stub
    }
    
    func load() async throws -> [FeedImage] {
        try stub.get()
    }
}
