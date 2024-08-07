//
//  FeedLoaderWithFallbackCompositeTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 07/08/2024.
//

import XCTest
import EssentialFeedAgain

final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader
    
    init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func load() async throws -> [FeedImage] {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()
        }
    }
}

final class FeedLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() async throws {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryStub: .success(primaryFeed), fallbackStub: .success(fallbackFeed))
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, primaryFeed)
    }
    
    func test_load_deliversFallbackFeedOnPrimaryFailure() async throws {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryStub: .failure(anyNSError()), fallbackStub: .success(fallbackFeed))
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, fallbackFeed)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryStub: LoaderStub.FeedStub,
                         fallbackStub: LoaderStub.FeedStub,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> FeedLoader {
        let primaryLoader = LoaderStub(stub: primaryStub)
        let fallbackLoader = LoaderStub(stub: fallbackStub)
        let sut = FeedLoaderWithFallbackComposite (primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }
    
    private func uniqueFeed() -> [FeedImage] {
        [FeedImage(id: UUID(), description: "any", location: "any", url: URL(string: "https://any-url.com")!)]
    }
    
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
