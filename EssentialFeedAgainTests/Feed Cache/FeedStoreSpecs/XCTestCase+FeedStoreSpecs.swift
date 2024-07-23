//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 19/07/2024.
//

import XCTest
import EssentialFeedAgain

extension FeedStoreSpecs where Self: XCTestCase {
    // MARK: - Retrieve
    
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore,
                                                     file: StaticString = #filePath,
                                                     line: UInt = #line) async throws {
        let received = try await sut.retrieve()
        
        XCTAssertNil(received, file: file, line: line)
    }
    
    func assertThatRetrieveTwiceHasNoSideEffectsOnEmptyCache(on sut: FeedStore,
                                                             file: StaticString = #filePath,
                                                             line: UInt = #line) async throws {
        let firstReceived = try await sut.retrieve()
        let secondReceived = try await sut.retrieve()
        
        XCTAssertNil(firstReceived, file: file, line: line)
        XCTAssertNil(secondReceived, file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore,
                                                              file: StaticString = #filePath,
                                                              line: UInt = #line) async throws {
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try await sut.insert(feed, timestamp: timestamp)
        let received = try await sut.retrieve()
        
        XCTAssertEqual(received?.feed, feed, file: file, line: line)
    }
    
    func assertThatRetrieveTwiceHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore,
                                                                file: StaticString = #filePath,
                                                                line: UInt = #line) async throws {
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try await sut.insert(feed, timestamp: timestamp)
        let firstReceived = try await sut.retrieve()
        let secondReceived = try await sut.retrieve()
        
        XCTAssertEqual(firstReceived?.feed, feed, file: file, line: line)
        XCTAssertEqual(secondReceived?.feed, feed, file: file, line: line)
    }
    
    // MARK: - Insert
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore,
                                                     file: StaticString = #filePath,
                                                     line: UInt = #line) async {
        await assertNoThrow(try await sut.insert(uniqueImageFeed().local, timestamp: .now))
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore,
                                                        file: StaticString = #filePath,
                                                        line: UInt = #line) async throws {
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        
        let lastFeed = uniqueImageFeed().local
        let lastTimestamp = Date.now
        await assertNoThrow(try await sut.insert(lastFeed, timestamp: lastTimestamp))
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore,
                                                                file: StaticString = #filePath,
                                                                line: UInt = #line) async throws {
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        
        let lastFeed = uniqueImageFeed().local
        let lastTimestamp = Date.now
        try await sut.insert(lastFeed, timestamp: lastTimestamp)
        
        let received = try await sut.retrieve()
        
        XCTAssertEqual(received?.feed, lastFeed)
        XCTAssertEqual(received?.timestamp, lastTimestamp)
    }
    
    // MARK: - Delete
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore,
                                                     file: StaticString = #filePath,
                                                     line: UInt = #line) async {
        await assertNoThrow(try await sut.deleteCachedFeed())
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore,
                                                      file: StaticString = #filePath,
                                                      line: UInt = #line) async throws {
        try await sut.deleteCachedFeed()
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore,
                                                        file: StaticString = #filePath,
                                                        line: UInt = #line) async throws {
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        
        await assertNoThrow(try await sut.deleteCachedFeed())
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore,
                                                        file: StaticString = #filePath,
                                                        line: UInt = #line) async throws {
        try await sut.insert(uniqueImageFeed().local, timestamp: .now)
        try await sut.deleteCachedFeed()
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
}
