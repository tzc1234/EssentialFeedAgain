//
//  CodableFeedStoreTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 18/07/2024.
//

import XCTest
import EssentialFeedAgain

final class CodableFeedStore {
    func retrieve() async throws -> (feed: [LocalFeedImage], timestamp: Date) {
        ([], .now)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = CodableFeedStore()
        
        let received = try await sut.retrieve()
        
        XCTAssertTrue(received.feed.isEmpty)
    }
}
