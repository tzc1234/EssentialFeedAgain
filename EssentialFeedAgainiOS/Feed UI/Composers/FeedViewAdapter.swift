//
//  FeedViewAdapter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import UIKit
import EssentialFeedAgain

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageDataLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageDataLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageDataLoader = imageDataLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.cellControllers = viewModel.feed.map { model in
            let adapter = FeedImageDataLoaderPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>>(
                model: model,
                imageDataLoader: imageDataLoader
            )
            let cellController = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(
                view: WeakRefVirtualProxy(cellController),
                imageTransformer: UIImage.init
            )
            return cellController
        }
    }
}
