//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 19/07/2024.
//

import XCTest
import EssentialFeedAgain

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversErrorOnRetrievalError(on sut: FeedStore,
                                                         file: StaticString = #filePath,
                                                         line: UInt = #line) async {
        await assertThrowsError(_ = try await sut.retrieve())
    }
    
    func assertThatRetrieveTwiceHasNoSideEffectsOnRetrievalError(on sut: FeedStore,
                                                                 file: StaticString = #filePath,
                                                                 line: UInt = #line) async {
        await assertThrowsError(_ = try await sut.retrieve())
        await assertThrowsError(_ = try await sut.retrieve())
    }
}
