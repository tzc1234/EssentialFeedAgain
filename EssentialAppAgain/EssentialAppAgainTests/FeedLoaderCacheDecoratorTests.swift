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
    private let cache: FeedCache
    
    init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    func load() async throws -> [FeedImage] {
        let feed = try await decoratee.load()
        try? await cache.save(feed)
        return feed
    }
}

final class FeedLoaderCacheDecoratorTests: XCTestCase {
    func test_load_deliversFeedOnLoaderSuccess() async throws {
        let feed = uniqueFeed()
        let (sut, _) = makeSUT(feedStub: .success(feed))
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, feed)
    }
    
    func test_load_deliversErrorOnLoaderFailure() async {
        let loaderError = anyNSError()
        let (sut, _) = makeSUT(feedStub: .failure(loaderError))
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    func test_load_cachesLoadedFeedOnLoaderSuccess() async throws {
        let feed = uniqueFeed()
        let (sut, cache) = makeSUT(feedStub: .success(feed))
        
        _ = try await sut.load()
        
        XCTAssertEqual(cache.messages, [.save(feed)])
    }
    
    func test_load_doesNotCacheOnLoaderFailure() async {
        let (sut, cache) = makeSUT(feedStub: .failure(anyNSError()))
        
        _ = try? await sut.load()
        
        XCTAssertEqual(cache.messages, [])
    }
    
    func test_load_ignoresCacheError() async {
        let feed = uniqueFeed()
        let (sut, _) = makeSUT(feedStub: .success(feed), cacheStub: .failure(anyNSError()))
        
        await assertNoThrow(_ = try await sut.load())
    }
    
    // MARK: - Helpers

    private func makeSUT(feedStub: FeedLoaderStub.FeedStub,
                         cacheStub: FeedCacheSpy.Stub = .success(()),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedLoader, cache: FeedCacheSpy) {
        let loader = FeedLoaderStub(stub: feedStub)
        let cache = FeedCacheSpy(stub: cacheStub)
        let sut = FeedLoaderCacheDecorator(decoratee: loader, cache: cache)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, cache)
    }
    
    private final class FeedCacheSpy: FeedCache {
        typealias Stub = Result<Void, Error>
        
        enum Message: Equatable {
            case save([FeedImage])
        }
        
        private(set) var messages = [Message]()
        private let stub: Stub
        
        init(stub: Stub) {
            self.stub = stub
        }
        
        func save(_ feed: [FeedImage]) async throws {
            messages.append(.save(feed))
            try stub.get()
        }
    }
}
