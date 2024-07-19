//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 19/07/2024.
//

import XCTest
import EssentialFeedAgain

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore,
                                                       file: StaticString = #filePath,
                                                       line: UInt = #line) async {
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        await assertThrowsError(try await sut.insert(feed, timestamp: timestamp))
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore,
                                                          file: StaticString = #filePath,
                                                          line: UInt = #line) async throws {
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        
        try? await sut.insert(feed, timestamp: timestamp)
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
}
