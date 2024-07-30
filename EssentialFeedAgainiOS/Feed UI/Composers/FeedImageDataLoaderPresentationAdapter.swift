//
//  FeedImageDataLoaderPresentationAdapter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import EssentialFeedAgain

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
