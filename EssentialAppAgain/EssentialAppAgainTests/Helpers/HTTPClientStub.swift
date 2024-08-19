//
//  HTTPClientStub.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 19/08/2024.
//

import Foundation
import EssentialFeedAgain

final class HTTPClientStub: HTTPClient {
    typealias Stub = (URL) async throws -> (Data, HTTPURLResponse)
    
    private let stub: Stub
    
    init(stub: @escaping Stub) {
        self.stub = stub
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        try await stub(url)
    }
}

extension HTTPClientStub {
    static var offline: HTTPClientStub {
        HTTPClientStub(stub: { _ in throw NSError(domain: "offline", code: 0) })
    }
    
    static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
        HTTPClientStub(stub: { url in stub(url) })
    }
}
