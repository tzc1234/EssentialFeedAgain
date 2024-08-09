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
}
