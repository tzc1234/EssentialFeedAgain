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
        let feedPresenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(presenter: feedPresenter)
        let feedController = FeedViewController(refreshController: refreshController)
        FeedImageCellController.registerCellFor(feedController.tableView)
        
        feedPresenter.loadingView = refreshController
        feedPresenter.feedView = FeedViewAdapter(controller: feedController, imageDataLoader: imageDataLoader)
        
        return feedController
    }
}

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageDataLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageDataLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageDataLoader = imageDataLoader
    }
    
    func display(feed: [FeedImage]) {
        controller?.cellControllers = feed.map { model in
            FeedImageCellController(
                viewModel: FeedImageViewModel<UIImage>(
                    model: model,
                    imageDataLoader: imageDataLoader,
                    imageTransformer: UIImage.init
                )
            )
        }
    }
}
