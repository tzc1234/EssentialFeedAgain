//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 16/07/2024.
//

import XCTest
import EssentialFeedAgain

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotNotifyStoreUponInit() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_load_requestsCacheRetrieval() async throws {
        let anyCache = [LocalFeedImage]()
        let (sut, store) = makeSUT(retrievalStubs: [success(with: anyCache, timestamp: .now)])
        
        _ = try await sut.load()
        
        XCTAssertEqual(store.messages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() async {
        let retrievalError = anyNSError()
        let (sut, _) = makeSUT(retrievalStubs: [.failure(retrievalError)])
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as NSError, retrievalError)
        }
    }
    
    func test_load_deliversNoImagesOnEmptyCache() async throws {
        let emptyCache = [LocalFeedImage]()
        let fixCurrentDate = Date.now
        let (sut, _) = makeSUT(
            currentDate: { fixCurrentDate },
            retrievalStubs: [success(with: emptyCache, timestamp: fixCurrentDate)]
        )
        
        let receivedImages = try await sut.load()
        
        XCTAssertTrue(receivedImages.isEmpty)
    }
    
    func test_load_deliversCachedImagesOnNonExpiredCache() async throws {
        let feed = uniqueImageFeed()
        let fixCurrentDate = Date.now
        let nonExpiredTimestamp = fixCurrentDate.minusMaxCacheAgeInDays().adding(seconds: 1)
        let (sut, _) = makeSUT(
            currentDate: { nonExpiredTimestamp }, 
            retrievalStubs: [success(with: feed.local, timestamp: nonExpiredTimestamp)]
        )
        
        let receivedImages = try await sut.load()
        
        XCTAssertEqual(receivedImages, feed.models)
    }

    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         deletionStubs: [FeedStoreSpy.DeletionStub] = [],
                         insertionStubs: [FeedStoreSpy.InsertionStub] = [],
                         retrievalStubs: [FeedStoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy(
            deletionStubs: deletionStubs,
            insertionStubs: insertionStubs,
            retrievalStubs: retrievalStubs
        )
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func success(with feed: [LocalFeedImage], timestamp: Date) -> FeedStoreSpy.RetrieveStub {
        .success((feed, timestamp))
    }
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let feed = [uniqueImage(), uniqueImage()]
        let localFeed = feed.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (feed, localFeed)
    }
    
    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
}

private extension Date {
    func minusMaxCacheAgeInDays() -> Date {
        adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int { 7 }
    
    func adding(days: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        calendar.date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
