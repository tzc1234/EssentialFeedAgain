//
//  FeedViewAdapter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import UIKit

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageDataLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageDataLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageDataLoader = imageDataLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.cellControllers = viewModel.feed.map { model in
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
