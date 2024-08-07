//
//  LocalFeedImageDataLoader.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 06/08/2024.
//

import Foundation

public final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

extension LocalFeedImageDataLoader {
    public enum SaveError: Error {
        case failed
    }
    
    public func save(_ data: Data, for url: URL) async throws {
        do {
            try await store.insert(data, for: url)
        } catch {
            throw SaveError.failed
        }
    }
}

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    public enum LoadError: Error {
        case failed
        case notFound
    }
    
    public func loadImageData(from url: URL) async throws -> Data {
        var data: Data?
        do {
            data = try await store.retrieve(dataFor: url)
        } catch {
            throw LoadError.failed
        }
        
        guard let data else { throw LoadError.notFound }
        
        return data
    }
}
