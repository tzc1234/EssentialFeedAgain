//
//  FeedLoaderCacheDecoratorTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 09/08/2024.
//

import XCTest
import EssentialFeedAgain

final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    
    init(decoratee: FeedLoader) {
        self.decoratee = decoratee
    }
    
    func load() async throws -> [FeedImage] {
        try await decoratee.load()
    }
}

final class FeedLoaderCacheDecoratorTests: XCTestCase {
    func test_load_deliversFeedOnLoaderSuccess() async throws {
        let feed = uniqueFeed()
        let loader = LoaderStub(stub: .success(feed))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, feed)
    }
    
    func test_load_deliversErrorOnLoaderFailure() async {
        let loaderError = anyNSError()
        let loader = LoaderStub(stub: .failure(loaderError))
        let sut = FeedLoaderCacheDecorator(decoratee: loader)
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    // MARK: - Helpers

    private final class LoaderStub: FeedLoader {
        typealias FeedStub = Result<[FeedImage], Error>
        
        private var stub: FeedStub
        
        init(stub: FeedStub) {
            self.stub = stub
        }
        
        func load() async throws -> [FeedImage] {
            try stub.get()
        }
    }
}
