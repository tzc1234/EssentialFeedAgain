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
    
    func test_get_requestsFromURL() {
        let sut = makeSUT()
        let url = URL(string: "https://request-url.com")!
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observe { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        _ = sut.get(from: url) { _ in }
        wait(for: [exp], timeout: 1)
    }
    
    func test_get_failsOnRequestError() throws {
        let expectedError = anyNSError()
        let requestError = try XCTUnwrap(errorFor((data: nil, response: nil, error: expectedError)) as? NSError)
        
        XCTAssertEqual(requestError.domain, expectedError.domain)
        XCTAssertEqual(requestError.code, expectedError.code)
    }
    
    func test_get_failsOnAllUnexpectedRepresentationErrors() {
        XCTAssertNotNil(errorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(errorFor((data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(errorFor((data: anyData(), response: nil, error: anyNSError())))
        XCTAssertNotNil(errorFor((data: anyData(), response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(errorFor((data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(errorFor((data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(errorFor((data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(errorFor((data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(errorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
    }
    
    func test_get_succeedsOnHTTPURLResponseWithData() throws {
        let expectedData = Data("data".utf8)
        let httpResponse = anyHTTPURLResponse()
        let (data, response) = try XCTUnwrap(valueFor((data: expectedData, response: httpResponse, error: nil)))
        
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(response.url, httpResponse.url)
        XCTAssertEqual(response.statusCode, httpResponse.statusCode)
    }
    
    func test_get_succeedsOnHTTPURLResponseWithNilData() throws {
        let httpResponse = anyHTTPURLResponse()
        let (data, response) = try XCTUnwrap(valueFor((data: nil, response: httpResponse, error: nil)))
        
        XCTAssertTrue(data.isEmpty)
        XCTAssertEqual(response.url, httpResponse.url)
        XCTAssertEqual(response.statusCode, httpResponse.statusCode)
    }
    
    func test_cancelTask_cancelsRequest() throws {
        let requestError = try XCTUnwrap(errorFor(taskHandler: { $0.cancel() }) as? NSError)
        
        XCTAssertEqual(requestError.code, URLError.cancelled.rawValue)
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func valueFor(_ value: (data: Data?, response: URLResponse?, error: Error?),
                          file: StaticString = #filePath,
                          line: UInt = #line) -> (Data, HTTPURLResponse)? {
        let result = resultFor(value, file: file, line: line)
        
        var receivedValue: (Data, HTTPURLResponse)?
        switch result {
        case let .success(value):
            receivedValue = value
        case .failure:
            XCTFail("Should be a success", file: file, line: line)
        }
        return receivedValue
    }
    
    private func errorFor(_ value: (data: Data?, response: URLResponse?, error: Error?)? = nil,
                          taskHandler: (HTTPClientTask) -> Void = { _ in },
                          file: StaticString = #filePath,
                          line: UInt = #line) -> Error? {
        let result = resultFor(value, taskHandler: taskHandler, file: file, line: line)
        
        var receivedError: Error?
        switch result {
        case .success:
            XCTFail("Should be a failure", file: file, line: line)
        case let .failure(error):
            receivedError = error
        }
        return receivedError
    }
    
    private func resultFor(_ value: (data: Data?, response: URLResponse?, error: Error?)? = nil,
                           taskHandler: (HTTPClientTask) -> Void = { _ in },
                           file: StaticString = #filePath,
                           line: UInt = #line) -> Result<(Data, HTTPURLResponse), Error> {
        let sut = makeSUT(file: file, line: line)
        value.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        var receivedResult: Result<(Data, HTTPURLResponse), Error>?
        let exp = expectation(description: "Wait for completion")
        taskHandler(sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        })
        wait(for: [exp], timeout: 1)
        return receivedResult!
    }
    
    private func anyData() -> Data {
        Data("any".utf8)
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
            stub = Stub(data: nil, response: nil, error: nil, observer: observer)
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
