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
    
    // MARK: - LocalFeedLoader Tests
    
    func test_loadFeed_deliversNoItemsOnEmptyCache() async throws {
        let feedLoader = try makeFeedLoader()
        
        let received = try await feedLoader.load()
        
        XCTAssertTrue(received.isEmpty)
    }
    
    func test_loadFeed_deliversItemsSavedOnSeparateInstances() async throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        try await feedLoaderToPerformSave.save(feed)
        let received = try await feedLoaderToPerformLoad.load()
        
        XCTAssertEqual(received, feed)
    }
    
    func test_saveFeed_overridesItemsSavedOnSeparateInstances() async throws {
        let feedLoaderToPerformFirstSave = try makeFeedLoader()
        let feedLoaderToPerformLastSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let firstFeed = uniqueImageFeed().models
        let lastFeed = uniqueImageFeed().models
        
        try await feedLoaderToPerformFirstSave.save(firstFeed)
        try await feedLoaderToPerformLastSave.save(lastFeed)
        let received = try await feedLoaderToPerformLoad.load()
        
        XCTAssertEqual(received, lastFeed)
    }
    
    // MARK: - LocalFeedImageDataLoader Tests
    
    func test_loadImageData_deliversSavedDataOnSeparateInstance() async throws {
        let imageLoaderToPerformSave = try makeImageLoader()
        let imageLoaderToPerformLoad = try makeImageLoader()
        let feedLoader = try makeFeedLoader()
        let image = uniqueImage()
        let dataToSave = anyData()
        
        try await feedLoader.save([image])
        try await imageLoaderToPerformSave.save(dataToSave, for: image.url)
        let receivedData = try await imageLoaderToPerformLoad.loadImageData(from: image.url)
        
        XCTAssertEqual(receivedData, dataToSave)
    }
    
    // MARK: - Helpers
    
    private func makeFeedLoader(file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedLoader {
        let store = try store(file: file, line: line)
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makeImageLoader(file: StaticString = #filePath, 
                                 line: UInt = #line) throws -> LocalFeedImageDataLoader {
        let store = try store(file: file, line: line)
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func store(file: StaticString = #filePath, line: UInt = #line) throws -> CoreDataFeedStore {
        let store = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(store, file: file, line: line)
        return store
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
