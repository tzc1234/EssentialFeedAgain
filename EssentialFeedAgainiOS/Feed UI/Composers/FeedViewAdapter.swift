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
            let adapter = FeedImageDataLoaderPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
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

final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image> where View.Image == Image {
    private(set) var task: Task<Void, Never>?
    var presenter: FeedImagePresenter<View, Image>?
    
    private let model: FeedImage
    private let imageDataLoader: FeedImageDataLoader
    
    init(model: FeedImage, imageDataLoader: FeedImageDataLoader) {
        self.model = model
        self.imageDataLoader = imageDataLoader
    }
}

extension FeedImageDataLoaderPresentationAdapter: FeedImageCellControllerDelegate {
    func loadImageData() {
        presenter?.didStartImageLoading(for: model)
        
        task = Task { @MainActor [weak self, model] in
            guard let self, !Task.isCancelled else { return }
            
            do {
                let data = try await imageDataLoader.loadImageData(from: model.url)
                presenter?.didFinishImageLoading(with: data, for: model)
            } catch {
                presenter?.didFinishImageLoadingWithError(for: model)
            }
        }
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
        task = nil
    }
}
