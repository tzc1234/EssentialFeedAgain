//
//  FeedImageDataLoaderWithFallbackCompositeTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 08/08/2024.
//

import XCTest
import EssentialFeedAgain
import EssentialAppAgain

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
    
    func test_loadImageData_deliversErrorOnBothPrimaryAndFallbackLoadersFailure() async {
        let (sut, _, _) = makeSUT(primaryStub: failure(), fallbackStub: failure())
        
        await assertThrowsError(_ = try await sut.loadImageData(from: anyURL()))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryStub: FeedImageDataLoaderSpy.Stub,
                         fallbackStub: FeedImageDataLoaderSpy.Stub,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedImageDataLoader, primary: FeedImageDataLoaderSpy, fallback: FeedImageDataLoaderSpy) {
        let primaryImageLoader = FeedImageDataLoaderSpy(stub: primaryStub)
        let fallbackImageLoader = FeedImageDataLoaderSpy(stub: fallbackStub)
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryImageLoader, fallback: fallbackImageLoader)
        trackForMemoryLeaks(primaryImageLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackImageLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryImageLoader, fallbackImageLoader)
    }
    
    private func failure() -> FeedImageDataLoaderSpy.Stub {
        .failure(anyNSError())
    }
    
    private func success(with data: Data) -> FeedImageDataLoaderSpy.Stub {
        .success(data)
    }
    
    private func anyData() -> Data {
        Data("any".utf8)
    }
}
