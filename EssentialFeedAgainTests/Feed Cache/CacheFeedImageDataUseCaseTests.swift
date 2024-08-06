//
//  CacheFeedImageDataUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 06/08/2024.
//

import XCTest
import EssentialFeedAgain

final class CacheFeedImageDataUseCaseTests: XCTestCase {
    func test_init_doseNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_save_requestsImageDataInsertionForURL() async {
        let (sut, store) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        let data = anyData()
        
        try? await sut.save(data, for: url)
        
        XCTAssertEqual(store.messages, [.insert(data, for: url)])
    }
    
    func test_save_failsOnStoreInsertionError() async throws {
        let insertionError = NSError(domain: "insertion error", code: 0)
        let (sut, _) = makeSUT(insertStubs: [.failure(insertionError)])
        
        await assertThrowsError(try await sut.save(anyData(), for: anyURL())) { error in
            XCTAssertEqual(error as? LocalFeedImageDataLoader.SaveError, .failed)
        }
    }
    
    func test_save_succeedsOnSuccessfulStoreInsertion() async throws {
        let (sut, _) = makeSUT(insertStubs: [.success(())])
        
        await assertNoThrow(try await sut.save(anyData(), for: anyURL()))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(insertStubs: [FeedImageDataStoreSpy.InsertStub] = [],
                         retrieveStubs: [FeedImageDataStoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
        let store = FeedImageDataStoreSpy(retrieveStubs: retrieveStubs, insertStubs: insertStubs)
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
