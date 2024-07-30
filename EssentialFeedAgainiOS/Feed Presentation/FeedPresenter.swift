//
//  FeedPresenter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import EssentialFeedAgain

struct FeedViewModel {
    let feed: [FeedImage]
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

struct FeedLoadingViewModel {
    let isLoading: Bool
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

final class FeedPresenter {
    private(set) var task: Task<Void, Never>?
    
    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            
            if let feed = try? await feedLoader.load() {
                feedView?.display(FeedViewModel(feed: feed))
            }
            
            loadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
