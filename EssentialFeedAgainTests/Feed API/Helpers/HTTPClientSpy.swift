//
//  HTTPClientSpy.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 30/04/2024.
//

import Foundation
import EssentialFeedAgain

final class HTTPClientSpy: HTTPClient {
    typealias Stub = Result<(Data, HTTPURLResponse), Error>
    
    private(set) var requestedURLs = [URL]()
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        
        guard !stubs.isEmpty else { return (Data(), HTTPURLResponse()) }
        
        return try stubs.removeFirst().get()
    }
}
