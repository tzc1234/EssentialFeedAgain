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
        let feedPresenter = FeedPresenter()
        let feedPresentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader, presenter: feedPresenter)
        let refreshController = FeedRefreshViewController(delegate: feedPresentationAdapter)
        let feedController = FeedViewController(refreshController: refreshController)
        FeedImageCellController.registerCellFor(feedController.tableView)
        
        feedPresenter.loadingView = WeakRefVirtualProxy(refreshController)
        feedPresenter.feedView = FeedViewAdapter(controller: feedController, imageDataLoader: imageDataLoader)
        
        return feedController
    }
}

final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

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

final class FeedLoaderPresentationAdapter: FeedRefreshViewControllerDelegate {
    private(set) var task: Task<Void, Never>?
    
    private let feedLoader: FeedLoader
    private let presenter: FeedPresenter
    
    init(feedLoader: FeedLoader, presenter: FeedPresenter) {
        self.feedLoader = feedLoader
        self.presenter = presenter
    }
    
    func didRequestFeedRefresh() {
        presenter.didStartLoadingFeed()
        
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            
            do {
                let feed = try await feedLoader.load()
                presenter.didFinishLoadingFeed(with: feed)
            } catch {
                presenter.didFinishLoadingFeedWithError()
            }
        }
    }
}
