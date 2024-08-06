//
//  LoadFeedImageDataFromCacheUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 06/08/2024.
//

import XCTest
import EssentialFeedAgain

final class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
    func test_init_doseNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_loadImageData_requestsCachedDataForURL() async {
        let (sut, store) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        
        _ = try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(store.messages, [.retrieve(dataFor: url)])
    }
    
    func test_loadImageData_failsOnStoreError() async {
        let retrievalError = anyNSError()
        let (sut, _) = makeSUT(retrieveStubs: [.failure(retrievalError)])
        
        await assertThrowsError(_ = try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as? LocalFeedImageDataLoader.LoadError, .failed)
        }
    }
    
    func test_loadImageData_deliversNotFoundErrorOnCacheNotFound() async throws {
        let (sut, _) = makeSUT(retrieveStubs: [.success(nil)])
        
        await assertThrowsError(_ = try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as? LocalFeedImageDataLoader.LoadError, .notFound)
        }
    }
    
    func test_loadImageData_deliversCachedDataOnFoundData() async throws {
        let foundData = anyData()
        let (sut, _) = makeSUT(retrieveStubs: [.success(foundData)])
        
        let receivedData = try await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(receivedData, foundData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(retrieveStubs: [FeedImageDataStoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedImageDataLoader, store: FeedImageDataStoreSpy) {
        let store = FeedImageDataStoreSpy(retrieveStubs: retrieveStubs)
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
