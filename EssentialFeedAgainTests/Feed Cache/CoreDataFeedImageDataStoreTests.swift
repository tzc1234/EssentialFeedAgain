//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 06/08/2024.
//

import XCTest
import EssentialFeedAgain

extension CoreDataFeedStore: FeedImageDataStore {
    public func insert(_ data: Data, for url: URL) async throws {
        
    }
    
    public func retrieve(dataFor url: URL) async throws -> Data? {
        return nil
    }
}

final class CoreDataFeedImageDataStoreTests: XCTestCase {
    func test_retrieveDataFor_deliversNoDataWhenEmpty() async throws {
        let sut = try makeSUT()
        
        let receivedData = try await sut.retrieve(dataFor: anyURL())
        
        XCTAssertNil(receivedData)
    }
    
    func test_retrieveDataFor_deliversNoDataWhenURLNotMatch() async throws {
        let sut = try makeSUT()
        let url = URL(string: "https://a-url.com")!
        let notMatchURL = URL(string: "https://not-match-url.com")!
        
        try await sut.insert(anyData(), for: url)
        let receivedData = try await sut.retrieve(dataFor: notMatchURL)
        
        XCTAssertNil(receivedData)
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> CoreDataFeedStore {
        let sut = try CoreDataFeedStore(storeURL: URL(filePath: "/dev/null"))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
