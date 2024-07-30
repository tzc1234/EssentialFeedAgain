//
//  FeedUIComposer.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit
import EssentialFeedAgain

public enum FeedUIComposer {
    public static func feedComposeWith(feedLoader: FeedLoader, 
                                       imageDataLoader: FeedImageDataLoader) -> FeedViewController {
        let feedPresentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(delegate: feedPresentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        FeedImageCellController.registerCellFor(feedController.tableView)
        
        let feedPresenter = FeedPresenter(
            feedView: FeedViewAdapter(controller: feedController, imageDataLoader: imageDataLoader),
            loadingView: WeakRefVirtualProxy(refreshController)
        )
        feedPresentationAdapter.presenter = feedPresenter
        
        return feedController
    }
}

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
