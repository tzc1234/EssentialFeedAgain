//
//  FeedStoreSpecs.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 19/07/2024.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() async throws
    func test_retrieveTwice_hasNoSideEffectsOnEmptyCache() async throws
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws
    func test_retrieveTwice_hasNoSideEffectsOnNonEmptyCache() async throws
    
    func test_insert_deliversNoErrorOnEmptyCache() async throws
    func test_insert_deliversNoErrorOnNonEmptyCache() async throws
    func test_insert_overridesPreviouslyInsertedCacheValues() async throws
    
    func test_delete_deliversNoErrorOnEmptyCache() async
    func test_delete_hasNoSideEffectsOnEmptyCache() async throws
    func test_delete_deliversNoErrorOnNonEmptyCache() async throws
    func test_delete_emptiesPreviouslyInsertedCache() async throws
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversErrorOnRetrievalError() async
    func test_retrieveTwice_hasNoSideEffectsOnRetrievalError() async
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError() async
    func test_insert_hasNoSideEffectsOnInsertionError() async throws
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError() async
    func test_delete_hasNoSideEffectsOnDeletionError() async throws
}

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs
    & FailableDeleteFeedStoreSpecs
