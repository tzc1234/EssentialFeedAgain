//
//  FeedImageViewModel.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 29/07/2024.
//

import Foundation
import EssentialFeedAgain

typealias Observer<T> = (T) -> Void

final class FeedImageViewModel<Image> {
    private(set) var task: Task<Void, Never>?
    
    var description: String? { model.description }
    var location: String? { model.location }
    var hasLocation: Bool { location != nil }
    
    var onImageLoad: Observer<Image>?
    var onLoading: Observer<Bool>?
    var onShouldRetry: Observer<Bool>?
    
    private let model: FeedImage
    private let imageDataLoader: FeedImageDataLoader
    private let imageTransformer: (Data) -> Image?
    
    init(model: FeedImage, imageDataLoader: FeedImageDataLoader, imageTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageDataLoader = imageDataLoader
        self.imageTransformer = imageTransformer
    }
    
    func loadImageData() {
        onLoading?(true)
        onShouldRetry?(false)
        
        task = Task { @MainActor [weak self, url = model.url] in
            guard let self else { return }
            
            defer { onLoading?(false) }
            
            guard !Task.isCancelled else { return }
            
            if let data = try? await imageDataLoader.loadImageData(from: url), let image = imageTransformer(data) {
                onImageLoad?(image)
            } else {
                onShouldRetry?(true)
            }
        }
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
        task = nil
    }
}
