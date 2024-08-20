//
//  FeedImagePresenter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import Foundation

public protocol FeedImageView {
    associatedtype Image
    
    func display(_ viewModel: FeedImageViewModel<Image>)
}

public final class FeedImagePresenter<View: FeedImageView> {
    private let view: View
    private let imageTransformer: (Data) -> View.Image?
    
    public init(view: View, imageTransformer: @escaping (Data) -> View.Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    public func didStartImageLoading(for model: FeedImage) {
        view.display(
            FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: true,
                shouldRetry: false
            )
        )
    }
    
    public func didFinishImageLoading(with data: Data, for model: FeedImage) {
        guard let image = imageTransformer(data) else {
            return didFinishImageLoadingWithError(for: model)
        }
        
        view.display(
            FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: image,
                isLoading: false,
                shouldRetry: false
            )
        )
    }
    
    public func didFinishImageLoadingWithError(for model: FeedImage) {
        view.display(
            FeedImageViewModel(
                description: model.description,
                location: model.location,
                image: nil,
                isLoading: false,
                shouldRetry: true
            )
        )
    }
}
