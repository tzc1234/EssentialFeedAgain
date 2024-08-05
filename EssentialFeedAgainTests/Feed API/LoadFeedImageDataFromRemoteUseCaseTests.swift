//
//  LoadFeedImageDataFromRemoteUseCaseTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 05/08/2024.
//

import XCTest
import EssentialFeedAgain

final class LoadFeedImageDataFromRemoteUseCaseTests: XCTestCase {
    func test_init_doseNotPerformURLRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadImageData_requestsDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT()
        
        _ = try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadImageDataTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT()
        
        _ = try? await sut.loadImageData(from: url)
        _ = try? await sut.loadImageData(from: url)
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadImageData_deliversErrorOnConnectivityError() async {
        let clientError = NSError(domain: "client error", code: 0)
        let (sut, _) = makeSUT(stubs: [.failure(clientError)])
        
        await assertThrowsError(_ = try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as? RemoteFeedImageDataLoader.Error, .connectivity)
        }
    }
    
    func test_loadImageData_deliversInvalidDataErrorOnNon200HTTPResponse() async {
        let samples = [199, 201, 300, 400, 500]
        let (sut, _) = makeSUT(stubs: samples.map { successOn(statusCode: $0) })
        
        for statusCode in samples {
            await assertThrowsError(
                _ = try await sut.loadImageData(from: anyURL()),
                "Expected an error on statusCode: \(statusCode)"
            ) { error in
                XCTAssertEqual(error as? RemoteFeedImageDataLoader.Error, .invalidData)
            }
        }
    }
    
    func test_loadImageData_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() async {
        let emptyData = Data()
        let (sut, _) = makeSUT(stubs: [successOn(data: emptyData)])
        
        await assertThrowsError(_ = try await sut.loadImageData(from: anyURL())) { error in
            XCTAssertEqual(error as? RemoteFeedImageDataLoader.Error, .invalidData)
        }
    }
    
    func test_loadImageData_deliversReceivedNonEmptyDataOn200Response() async throws {
        let nonEmptyData = anyData()
        let (sut, _) = makeSUT(stubs: [successOn(data: nonEmptyData)])
        
        let receivedData = try await sut.loadImageData(from: anyURL())
        
        XCTAssertEqual(receivedData, nonEmptyData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stubs: [HTTPClientSpy.Stub] = [], 
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteFeedImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy(stubs: stubs)
        let sut = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func successOn(data: Data) -> HTTPClientSpy.Stub {
        .success((data, HTTPURLResponse(statusCode: 200)))
    }
    
    private func successOn(statusCode: Int) -> HTTPClientSpy.Stub {
        .success((anyData(), HTTPURLResponse(statusCode: statusCode)))
    }
}
