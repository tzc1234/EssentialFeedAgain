//
//  LoadFeedImageDataFromCacheUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 06/08/2024.
//

import XCTest

final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore
    
    init(store: FeedImageDataStore) {
        self.store = store
    }
    
    enum Error: Swift.Error {
        case failed
        case notFound
    }
    
    func loadImageData(from url: URL) async throws {
        do {
            guard let data = try store.retrieve(dataFor: url) else {
                throw Error.notFound
            }
        } catch Error.notFound {
            throw Error.notFound
        } catch {
            throw Error.failed
        }
    }
}

protocol FeedImageDataStore {
    func retrieve(dataFor url: URL) throws -> Data?
}

final class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
    func test_init_doseNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_loadImageData_requestsCachedDataForURL() async {
        let (sut, store) = makeSUT()
        let url = URL(string: "https://a-given-url.com")!
        
        try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(store.messages, [.retrieve(dataFor: url)])
    }
    
    func test_loadImageData_failsOnStoreError() async {
        let retrievalError = anyNSError()
        let (sut, store) = makeSUT(retrieveStubs: [.failure(retrievalError)])
        
        await assertThrowsError(try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as? LocalFeedImageDataLoader.Error, .failed)
        }
    }
    
    func test_loadImageData_deliversNotFoundErrorOnCacheNotFound() async throws {
        let (sut, store) = makeSUT(retrieveStubs: [.success(nil)])
        
        await assertThrowsError(try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as? LocalFeedImageDataLoader.Error, .notFound)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(retrieveStubs: [StoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: StoreSpy) {
        let store = StoreSpy(retrieveStubs: retrieveStubs)
        let sut = LocalFeedImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    final class StoreSpy: FeedImageDataStore {
        typealias RetrieveStub = Result<Data?, Error>
        
        enum Message: Equatable {
            case retrieve(dataFor: URL)
        }
        
        private(set) var messages = [Message]()
        private var retrieveStubs = [RetrieveStub]()
        
        init(retrieveStubs: [RetrieveStub]) {
            self.retrieveStubs = retrieveStubs
        }
        
        func retrieve(dataFor url: URL) throws -> Data? {
            messages.append(.retrieve(dataFor: url))
            
            guard !retrieveStubs.isEmpty else { return nil }
            
            return try retrieveStubs.removeFirst().get()
        }
    }
}
