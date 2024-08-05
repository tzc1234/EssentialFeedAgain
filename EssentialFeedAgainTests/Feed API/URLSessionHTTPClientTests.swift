//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 30/04/2024.
//

import XCTest
import EssentialFeedAgain

final class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.reset()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.reset()
    }
    
    func test_get_requestsFromURL() async {
        let sut = makeSUT()
        let url = URL(string: "https://request-url.com")!
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observe { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        _ = try? await sut.get(from: url)
        
        await fulfillment(of: [exp])
    }
    
    func test_get_failsOnRequestError() async throws {
        let expectedError = anyNSError()
        
        let received = await errorFor((data: nil, response: nil, error: expectedError))
        let requestError = try XCTUnwrap(received as? NSError)
        
        XCTAssertEqual(requestError.domain, expectedError.domain)
        XCTAssertEqual(requestError.code, expectedError.code)
    }
    
    func test_get_failsOnAllUnexpectedRepresentationErrors() async {
        await assertErrorNotNil(when: (data: anyData(), response: nil, error: anyNSError()))
        await assertErrorNotNil(when: (data: anyData(), response: nonHTTPURLResponse(), error: nil))
        await assertErrorNotNil(when: (data: nil, response: nonHTTPURLResponse(), error: nil))
        await assertErrorNotNil(when: (data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        await assertErrorNotNil(when: (data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        await assertErrorNotNil(when: (data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        await assertErrorNotNil(when: (data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
    }
    
    func test_get_succeedsOnHTTPURLResponseAndData() async throws {
        let expectedData = Data("data".utf8)
        let httpResponse = anyHTTPURLResponse()
        
        let received = await valueFor((data: expectedData, response: httpResponse, error: nil))
        let (data, response) = try XCTUnwrap(received)
        
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(response.url, httpResponse.url)
        XCTAssertEqual(response.statusCode, httpResponse.statusCode)
    }
    
    func test_get_succeedsWithEmptyDataOnHTTPURLResponseAndNilData() async throws {
        let httpResponse = anyHTTPURLResponse()
        
        let received = await valueFor((data: nil, response: httpResponse, error: nil))
        let (data, response) = try XCTUnwrap(received)
        
        let emptyData = Data()
        XCTAssertEqual(data, emptyData)
        XCTAssertEqual(response.url, httpResponse.url)
        XCTAssertEqual(response.statusCode, httpResponse.statusCode)
    }
    
    func test_cancelTask_cancelsRequest() async {
        let sut = makeSUT()
        let task = Task {
            _ = try await sut.get(from: anyURL())
        }
        
        task.cancel()
        
        await assertThrowsError(try await task.value) { error in
            XCTAssertEqual((error as NSError).code, URLError.cancelled.rawValue)
        }
    }

    // MARK: - Helpers
    
    private typealias Value = (data: Data?, response: URLResponse?, error: Error?)
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func assertErrorNotNil(when value: Value,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) async {
        let error = await errorFor(value, file: file, line: line)
        XCTAssertNotNil(error, file: file, line: line)
    }
    
    private func valueFor(_ value: Value,
                          file: StaticString = #filePath,
                          line: UInt = #line) async -> (Data, HTTPURLResponse)? {
        do {
            return try await resultFor(value, file: file, line: line)
        } catch {
            XCTFail("Should be a success", file: file, line: line)
            return nil
        }
    }
    
    private func errorFor(_ value: Value,
                          file: StaticString = #filePath,
                          line: UInt = #line) async -> Error? {
        
        do {
            _ = try await resultFor(value, file: file, line: line)
            XCTFail("Should be an error", file: file, line: line)
            return nil
        } catch {
            return error
        }
    }
    
    private func resultFor(_ value: Value,
                           file: StaticString = #filePath,
                           line: UInt = #line) async throws -> (Data, HTTPURLResponse) {
        let sut = makeSUT(file: file, line: line)
        URLProtocolStub.stub(data: value.data, response: value.response, error: value.error)
        return try await sut.get(from: anyURL())
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(statusCode: 200)
    }
    
    private final class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
            let observer: ((URLRequest) -> Void)?
        }
        
        private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
        private static var _stub: Stub?
        private static var stub: Stub? {
            get { queue.sync { _stub } }
            set { queue.sync { _stub = newValue } }
        }
        
        static func observe(_ observer: @escaping (URLRequest) -> Void) {
            stub = Stub(data: nil, response: nil, error: anyNSError(), observer: observer)
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error, observer: nil)
        }
        
        static func reset() {
            stub = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            let stub = Self.stub
            
            if let data = stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
            
            stub?.observer?(request)
        }
        
        override func stopLoading() {}
    }
}
