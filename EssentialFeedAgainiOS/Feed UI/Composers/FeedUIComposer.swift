//
//  FeedUIComposer.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import EssentialFeedAgain

public enum FeedUIComposer {
    public static func feedComposeWith(feedLoader: FeedLoader, 
                                       imageDataLoader: FeedImageDataLoader) -> FeedViewController {
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: feedViewModel)
        let feedController = FeedViewController(refreshController: refreshController)
        FeedImageCellController.registerCellFor(feedController.tableView)
        
        feedViewModel.onFeedLoad = { [weak feedController] feed in
            feedController?.cellControllers = feed.map { model in
                FeedImageCellController(model: model, imageDataLoader: imageDataLoader)
            }
        }
        
        return feedController
    }
}
