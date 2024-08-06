//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 06/08/2024.
//

import XCTest
import EssentialFeedAgain

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
        
        try await insert(data: anyData(), for: url, into: sut)
        let receivedData = try await sut.retrieve(dataFor: notMatchURL)
        
        XCTAssertNil(receivedData)
    }
    
    func test_retrieveDataFor_deliversFoundDataWhenStoredDataMatchingURL() async throws {
        let sut = try makeSUT()
        let url = URL(string: "https://a-url.com")!
        let storedData = Data("stored".utf8)
        
        try await insert(data: storedData, for: url, into: sut)
        let receivedData = try await sut.retrieve(dataFor: url)
        
        XCTAssertEqual(receivedData, storedData)
    }
    
    func test_retrieveDataFor_deliversLastInsertedData() async throws {
        let sut = try makeSUT()
        let url = URL(string: "https://a-url.com")!
        let firstStoredData = Data("first".utf8)
        let lastStoredData = Data("last".utf8)
        
        try await insert(data: firstStoredData, for: url, into: sut)
        try await insert(data: lastStoredData, for: url, into: sut)
        let receivedData = try await sut.retrieve(dataFor: url)
        
        XCTAssertEqual(receivedData, lastStoredData)
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> CoreDataFeedStore {
        let sut = try CoreDataFeedStore(storeURL: URL(filePath: "/dev/null"))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func insert(data: Data, for url: URL, into sut: CoreDataFeedStore) async throws {
        try await sut.insert([makeFeedImage(for: url)], timestamp: .now)
        try await sut.insert(data, for: url)
    }
    
    private func makeFeedImage(for url: URL) -> LocalFeedImage {
        LocalFeedImage(id: UUID(), description: nil, location: nil, url: url)
    }
}
