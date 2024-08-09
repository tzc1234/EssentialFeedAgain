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
    
    init(decoratee: FeedImageDataLoader) {
        self.decoratee = decoratee
    }
    
    func loadImageData(from url: URL) async throws -> Data {
        try await decoratee.loadImageData(from: url)
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
    
    // MARK: - Helpers
    
    private func makeSUT(imageDataStub: FeedImageDataLoaderSpy.Stub = .success(Data()),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedImageDataLoader, loader: FeedImageDataLoaderSpy) {
        let loader = FeedImageDataLoaderSpy(stub: imageDataStub)
        let sut = FeedImageDataLoaderCacheDecorator(decoratee: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private class FeedImageDataLoaderSpy: FeedImageDataLoader {
        typealias Stub = Result<Data, Error>
        
        private(set) var loadURLs = [URL]()
        private let stub: Stub
        
        init(stub: Stub) {
            self.stub = stub
        }
        
        func loadImageData(from url: URL) async throws -> Data {
            loadURLs.append(url)
            return try stub.get()
        }
    }
}
