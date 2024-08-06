//
//  LocalFeedImageDataLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

public final class LocalFeedImageDataLoader: FeedImageDataLoader {
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
    
    public enum Error: Swift.Error {
        case failed
        case notFound
    }
    
    public func loadImageData(from url: URL) async throws -> Data {
        do {
            guard let data = try store.retrieve(dataFor: url) else {
                throw Error.notFound
            }
            
            return data
        } catch Error.notFound {
            throw Error.notFound
        } catch {
            throw Error.failed
        }
    }
}
