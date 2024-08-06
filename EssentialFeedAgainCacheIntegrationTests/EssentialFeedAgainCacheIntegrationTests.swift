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
    
    func test_load_deliversNoItemsOnEmptyCache() async throws {
        let sut = try makeFeedLoader()
        
        let received = try await sut.load()
        
        XCTAssertTrue(received.isEmpty)
    }
    
    func test_load_deliversItemsSavedOnSeparateInstances() async throws {
        let sutPerformSave = try makeFeedLoader()
        let sutPerformLoad = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        try await sutPerformSave.save(feed)
        let received = try await sutPerformLoad.load()
        
        XCTAssertEqual(received, feed)
    }
    
    func test_save_overridesItemsSavedOnSeparateInstances() async throws {
        let sutPerformFirstSave = try makeFeedLoader()
        let sutPerformLastSave = try makeFeedLoader()
        let sutPerformLoad = try makeFeedLoader()
        let firstFeed = uniqueImageFeed().models
        let lastFeed = uniqueImageFeed().models
        
        try await sutPerformFirstSave.save(firstFeed)
        try await sutPerformLastSave.save(lastFeed)
        let received = try await sutPerformLoad.load()
        
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
