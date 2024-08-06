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
        
        let receivedFeed = try await feedLoader.load()
        
        XCTAssertTrue(receivedFeed.isEmpty)
    }
    
    func test_loadFeed_deliversItemsSavedOnSeparateInstances() async throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        try await feedLoaderToPerformSave.save(feed)
        let receivedFeed = try await feedLoaderToPerformLoad.load()
        
        XCTAssertEqual(receivedFeed, feed)
    }
    
    func test_saveFeed_overridesItemsSavedOnSeparateInstances() async throws {
        let feedLoaderToPerformFirstSave = try makeFeedLoader()
        let feedLoaderToPerformLastSave = try makeFeedLoader()
        let feedLoaderToPerformLoad = try makeFeedLoader()
        let firstFeed = uniqueImageFeed().models
        let lastFeed = uniqueImageFeed().models
        
        try await feedLoaderToPerformFirstSave.save(firstFeed)
        try await feedLoaderToPerformLastSave.save(lastFeed)
        let receivedFeed = try await feedLoaderToPerformLoad.load()
        
        XCTAssertEqual(receivedFeed, lastFeed)
    }
    
    func test_validateFeedCache_doesNotDeleteRecentlySavedFeed() async throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformValidation = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        try await feedLoaderToPerformSave.save(feed)
        await feedLoaderToPerformValidation.validateCache()
        let receivedFeed = try await feedLoaderToPerformSave.load()
        
        XCTAssertEqual(receivedFeed, feed)
    }
    
    func test_validateFeedCache_deletesFeedSavedInADistancePast() async throws {
        let feedLoaderToPerformSave = try makeFeedLoader(currentDate: .distantPast)
        let feedLoaderToPerformValidation = try makeFeedLoader(currentDate: .now)
        let feed = uniqueImageFeed().models
        
        try await feedLoaderToPerformSave.save(feed)
        await feedLoaderToPerformValidation.validateCache()
        let receivedFeed = try await feedLoaderToPerformSave.load()
        
        XCTAssertEqual(receivedFeed, [])
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
    
    func test_saveImageData_overridesSavedImageDataOnSeparateInstance() async throws {
        let imageLoaderToPerformFirstSave = try makeImageLoader()
        let imageLoaderToPerformLastSave = try makeImageLoader()
        let imageLoaderToPerformLoad = try makeImageLoader()
        let feedLoader = try makeFeedLoader()
        let image = uniqueImage()
        let firstImageData = Data("first".utf8)
        let lastImageData = Data("last".utf8)
        
        try await feedLoader.save([image])
        try await imageLoaderToPerformFirstSave.save(firstImageData, for: image.url)
        try await imageLoaderToPerformLastSave.save(lastImageData, for: image.url)
        let receivedData = try await imageLoaderToPerformLoad.loadImageData(from: image.url)
        
        XCTAssertEqual(receivedData, lastImageData)
    }
    
    // MARK: - Helpers
    
    private func makeFeedLoader(currentDate: Date = Date(),
                                file: StaticString = #filePath,
                                line: UInt = #line) throws -> LocalFeedLoader {
        let store = try store(file: file, line: line)
        let sut = LocalFeedLoader(store: store, currentDate: { currentDate })
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
