//
//  FeedImageViewModel.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 29/07/2024.
//

import UIKit
import EssentialFeedAgain

final class FeedImageViewModel {
    private(set) var task: Task<Void, Never>?
    
    var description: String? { model.description }
    var location: String? { model.location }
    var hasLocation: Bool { location != nil }
    
    var onImageLoad: Observer<UIImage>?
    var onLoading: Observer<Bool>?
    var onShouldRetry: Observer<Bool>?
    
    private let model: FeedImage
    private let imageDataLoader: FeedImageDataLoader
    
    init(model: FeedImage, imageDataLoader: FeedImageDataLoader) {
        self.model = model
        self.imageDataLoader = imageDataLoader
    }
    
    func loadImageData() {
        onLoading?(true)
        onShouldRetry?(false)
        
        task = Task { @MainActor [weak self, url = model.url] in
            guard let self else { return }
            
            defer { onLoading?(false) }
            
            guard !Task.isCancelled else { return }
            
            if let data = try? await imageDataLoader.loadImageData(from: url), let image = UIImage(data: data) {
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
