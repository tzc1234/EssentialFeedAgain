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
        try await primary.loadImageData(from: url)
    }
}

final class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() async throws {
        let primaryData = Data("primary".utf8)
        let fallbackData = Data("fallback".utf8)
        let primaryImageLoader = LoaderSpy(stub: .success(primaryData))
        let fallbackImageLoader = LoaderSpy(stub: .success(fallbackData))
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryImageLoader, fallback: fallbackImageLoader)
        
        let receivedData = try await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(receivedData, primaryData)
    }
    
    // MARK: - Helpers
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private class LoaderSpy: FeedImageDataLoader {
        typealias Stub = Result<Data, Error>
        
        private let stub: Stub
        
        init(stub: Stub) {
            self.stub = stub
        }
        
        func loadImageData(from url: URL) async throws -> Data {
            try stub.get()
        }
    }
}
