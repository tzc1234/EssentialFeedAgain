//
//  FeedImageDataLoaderSpy.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 09/08/2024.
//

import Foundation
import EssentialFeedAgain

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
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
