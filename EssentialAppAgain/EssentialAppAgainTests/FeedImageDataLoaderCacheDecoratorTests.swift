//
//  FeedImageDataLoaderCacheDecoratorTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 09/08/2024.
//

import XCTest
import EssentialFeedAgain

final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {
    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache
    
    init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    func loadImageData(from url: URL) async throws -> Data {
        let data = try await decoratee.loadImageData(from: url)
        try? await cache.save(data, for: url)
        return data
    }
}

final class FeedImageDataLoaderCacheDecoratorTests: XCTestCase {
    func test_init_doesNotLoadImageData() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loadURLs.isEmpty)
    }
    
    func test_loadImageData_loadsFromLoader() async {
        let (sut, loader) = makeSUT()
        let url = anyURL()
        
        _ = try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(loader.loadURLs, [url])
    }
    
    func test_loadImageData_deliversDataOnLoaderSuccess() async throws {
        let imageData = anyData()
        let (sut, _) = makeSUT(imageDataStub: .success(imageData))
        
        let receivedData = try await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(receivedData, imageData)
    }
    
    func test_loadImageData_deliversErrorOnLoaderFailure() async {
        let loaderError = anyNSError()
        let (sut, _) = makeSUT(imageDataStub: .failure(loaderError))
        
        await assertThrowsError(_ = try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    func test_loadImageData_cachesLoadedDataOnLoaderSuccess() async throws {
        let cache = CacheSpy()
        let url = anyURL()
        let imageData = anyData()
        let (sut, _) = makeSUT(imageDataStub: .success(imageData), cache: cache)
        
        _ = try await sut.loadImageData(from: url)
        
        XCTAssertEqual(cache.messages, [.save(imageData, for: url)])
    }
    
    func test_loadImageData_doseNotCacheOnLoaderFailure() async {
        let cache = CacheSpy()
        let (sut, _) = makeSUT(imageDataStub: .failure(anyNSError()), cache: cache)
        
        _ = try? await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(cache.messages, [])
    }
    
    func test_loadImageData_ignoresCacheError() async {
        let cache = CacheSpy(stub: .failure(anyNSError()))
        let imageData = anyData()
        let (sut, _) = makeSUT(imageDataStub: .success(imageData), cache: cache)
        
        await assertNoThrow(_ = try await sut.loadImageData(from: anyURL()))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(imageDataStub: FeedImageDataLoaderSpy.Stub = .success(Data()),
                         cache: FeedImageDataCache? = nil,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedImageDataLoader, loader: FeedImageDataLoaderSpy) {
        let loader = FeedImageDataLoaderSpy(stub: imageDataStub)
        let sut = FeedImageDataLoaderCacheDecorator(decoratee: loader, cache: cache ?? CacheSpy())
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private final class CacheSpy: FeedImageDataCache {
        typealias Stub = Result<Void, Error>
        
        enum Message: Equatable {
            case save(Data, for: URL)
        }
        
        private(set) var messages = [Message]()
        private let stub: Stub
        
        init(stub: Stub = .success(())) {
            self.stub = stub
        }
        
        func save(_ data: Data, for url: URL) async throws {
            messages.append(.save(data, for: url))
            try stub.get()
        }
    }
}
