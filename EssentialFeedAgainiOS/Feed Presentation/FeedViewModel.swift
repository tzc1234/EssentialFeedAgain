//
//  FeedViewModel.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 29/07/2024.
//

import EssentialFeedAgain

typealias Observer<T> = (T) -> Void

final class FeedViewModel {
    private(set) var task: Task<Void, Never>?
    
    var onLoading: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        onLoading?(true)
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            
            if let feed = try? await feedLoader.load() {
                onFeedLoad?(feed)
            }
            
            onLoading?(false)
        }
    }
}
