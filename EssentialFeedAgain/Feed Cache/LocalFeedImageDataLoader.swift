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
        do {
            guard let data = try await store.retrieve(dataFor: url) else {
                throw LoadError.notFound
            }
            
            return data
        } catch LoadError.notFound {
            throw LoadError.notFound
        } catch {
            throw LoadError.failed
        }
    }
}
