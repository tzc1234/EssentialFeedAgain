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
        let sut = makeSUT(stub: .success(feed))
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, feed)
    }
    
    func test_load_deliversErrorOnLoaderFailure() async {
        let loaderError = anyNSError()
        let sut = makeSUT(stub: .failure(loaderError))
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    // MARK: - Helpers

    private func makeSUT(stub: FeedLoaderStub.FeedStub,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> FeedLoader {
        let loader = FeedLoaderStub(stub: stub)
        let sut = FeedLoaderCacheDecorator(decoratee: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
