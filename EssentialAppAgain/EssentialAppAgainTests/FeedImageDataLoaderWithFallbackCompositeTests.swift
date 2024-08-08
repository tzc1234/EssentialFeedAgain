//
//  FeedImageDataLoaderWithFallbackCompositeTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 08/08/2024.
//

import XCTest
import EssentialFeedAgain

final class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader
    
    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func loadImageData(from url: URL) async throws -> Data {
        do {
            return try await primary.loadImageData(from: url)
        } catch {
            return try await fallback.loadImageData(from: url)
        }
    }
}

final class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_loadImageData_loadsFromPrimaryLoaderFirst() async throws {
        let (sut, primaryImageLoader, fallbackImageLoader) = makeSUT(
            primaryStub: success(with: anyData()),
            fallbackStub: success(with: anyData())
        )
        let url = anyURL()
        
        _ = try await sut.loadImageData(from: url)
        
        XCTAssertEqual(primaryImageLoader.loadURLs, [url])
        XCTAssertEqual(fallbackImageLoader.loadURLs, [])
    }
    
    func test_loadImageData_loadsFromFallbackLoaderOnPrimaryLoaderFailure() async throws {
        let (sut, primaryImageLoader, fallbackImageLoader) = makeSUT(
            primaryStub: failure(),
            fallbackStub: success(with: anyData())
        )
        let url = anyURL()
        
        _ = try await sut.loadImageData(from: url)
        
        XCTAssertEqual(primaryImageLoader.loadURLs, [url])
        XCTAssertEqual(fallbackImageLoader.loadURLs, [url])
    }
    
    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() async throws {
        let primaryData = Data("primary".utf8)
        let fallbackData = Data("fallback".utf8)
        let (sut, _, _) = makeSUT(primaryStub: success(with: primaryData), fallbackStub: success(with: fallbackData))
        
        let receivedData = try await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(receivedData, primaryData)
    }
    
    func test_loadImageData_deliversFallbackDataOnPrimaryLoaderFailure() async throws {
        let fallbackData = Data("fallback".utf8)
        let (sut, _, _) = makeSUT(primaryStub: failure(), fallbackStub: success(with: fallbackData))
        
        let receivedData = try await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(receivedData, fallbackData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryStub: LoaderSpy.Stub,
                         fallbackStub: LoaderSpy.Stub,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedImageDataLoader, primary: LoaderSpy, fallback: LoaderSpy) {
        let primaryImageLoader = LoaderSpy(stub: primaryStub)
        let fallbackImageLoader = LoaderSpy(stub: fallbackStub)
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryImageLoader, fallback: fallbackImageLoader)
        trackForMemoryLeaks(primaryImageLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackImageLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryImageLoader, fallbackImageLoader)
    }
    
    private func failure() -> LoaderSpy.Stub {
        .failure(anyNSError())
    }
    
    private func success(with data: Data) -> LoaderSpy.Stub {
        .success(data)
    }
    
    private func anyData() -> Data {
        Data("any".utf8)
    }
    
    private class LoaderSpy: FeedImageDataLoader {
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