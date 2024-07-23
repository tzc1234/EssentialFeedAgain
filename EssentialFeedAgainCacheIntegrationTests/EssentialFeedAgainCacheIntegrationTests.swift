//
//  EssentialFeedAgainCacheIntegrationTests.swift
//  EssentialFeedAgainCacheIntegrationTests
//
//  Created by Tsz-Lung on 23/07/2024.
//

import XCTest
import EssentialFeedAgain

final class EssentialFeedAgainCacheIntegrationTests: XCTestCase {
    func test_load_deliversNoItemsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        let received = try await sut.load()
        
        XCTAssertTrue(received.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedLoader {
        let store = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        cacheDirectory().appending(path: "\(type(of: self)).store")
    }
    
    private func cacheDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
