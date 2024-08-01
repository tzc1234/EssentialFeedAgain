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
        feedController.title = FeedPresenter.title
        FeedImageCellController.registerCellFor(feedController.tableView)
        
        let feedPresenter = FeedPresenter(
            feedView: FeedViewAdapter(controller: feedController, imageDataLoader: imageDataLoader),
            loadingView: WeakRefVirtualProxy(refreshController)
        )
        feedPresentationAdapter.presenter = feedPresenter
        
        return feedController
    }
}
