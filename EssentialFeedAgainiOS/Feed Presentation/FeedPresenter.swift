//
//  FeedPresenter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import EssentialFeedAgain

protocol FeedView {
    func display(feed: [FeedImage])
}

protocol FeedLoadingView: AnyObject {
    func display(isLoading: Bool)
}

final class FeedPresenter {
    private(set) var task: Task<Void, Never>?
    
    var feedView: FeedView?
    weak var loadingView: FeedLoadingView?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        loadingView?.display(isLoading: true)
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            
            if let feed = try? await feedLoader.load() {
                feedView?.display(feed: feed)
            }
            
            loadingView?.display(isLoading: false)
        }
    }
}
