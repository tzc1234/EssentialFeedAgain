//
//  FeedLoaderPresentationAdapter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import EssentialFeedAgain
import EssentialFeedAgainiOS

final class FeedLoaderPresentationAdapter: FeedRefreshViewControllerDelegate {
    private(set) var task: Task<Void, Never>?
    
    var presenter: FeedPresenter?
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func didRequestFeedRefresh() {
        presenter?.didStartLoadingFeed()
        
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            
            do {
                let feed = try await feedLoader.load()
                presenter?.didFinishLoadingFeed(with: feed)
            } catch {
                presenter?.didFinishLoadingFeedWithError()
            }
        }
    }
}
