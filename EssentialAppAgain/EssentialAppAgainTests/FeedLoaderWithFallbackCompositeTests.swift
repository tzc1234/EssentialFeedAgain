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
        try await primary.load()
    }
}

final class FeedLoaderWithFallbackCompositeTests: XCTestCase {
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() async throws {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let primaryLoader = LoaderStub(stub: .success(primaryFeed))
        let fallbackLoader = LoaderStub(stub: .success(fallbackFeed))
        let sut = FeedLoaderWithFallbackComposite (primary: primaryLoader, fallback: fallbackLoader)
        
        let receivedFeed = try await sut.load()
        
        XCTAssertEqual(receivedFeed, primaryFeed)
    }
    
    // MARK: - Helpers
    
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
