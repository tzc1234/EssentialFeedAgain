//
//  EssentialFeedAgainCacheIntegrationTests.swift
//  EssentialFeedAgainCacheIntegrationTests
//
//  Created by Tsz-Lung on 23/07/2024.
//

import XCTest
import EssentialFeedAgain

final class EssentialFeedAgainCacheIntegrationTests: XCTestCase {
    override func tearDown() async throws {
        try await super.tearDown()
        
        try removeAllArtefactsAfterTest()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        let received = try await sut.load()
        
        XCTAssertTrue(received.isEmpty)
    }
    
    func test_load_deliversItemsSavedOnSeparateInstances() async throws {
        let sutPerformSave = try makeSUT()
        let sutPerformLoad = try makeSUT()
        let feed = uniqueImageFeed().models
        
        try await sutPerformSave.save(feed)
        let received = try await sutPerformLoad.load()
        
        XCTAssertEqual(received, feed)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedLoader {
        let store = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func removeAllArtefactsAfterTest() throws {
        try FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        cacheDirectory().appending(path: "\(type(of: self)).store")
    }
    
    private func cacheDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
