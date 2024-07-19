//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 19/07/2024.
//

import XCTest
import EssentialFeedAgain

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore,
                                                      file: StaticString = #filePath,
                                                      line: UInt = #line) async {
        await assertThrowsError(try await sut.deleteCachedFeed())
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore,
                                                         file: StaticString = #filePath,
                                                         line: UInt = #line) async throws {
        try? await sut.deleteCachedFeed()
        let received = try await sut.retrieve()
        
        XCTAssertNil(received)
    }
}
