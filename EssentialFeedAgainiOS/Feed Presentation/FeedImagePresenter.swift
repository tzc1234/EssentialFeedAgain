//
//  FeedImagePresenter.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import Foundation
import EssentialFeedAgain

protocol FeedImageView {
    associatedtype Image
    
    func display(_ viewModel: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView> {
    private let view: View
    private let imageTransformer: (Data) -> View.Image?
    
    init(view: View, imageTransformer: @escaping (Data) -> View.Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    func didStartImageLoading(for model: FeedImage) {
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
    
    func didFinishImageLoading(with data: Data, for model: FeedImage) {
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
    
    func didFinishImageLoadingWithError(for model: FeedImage) {
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
