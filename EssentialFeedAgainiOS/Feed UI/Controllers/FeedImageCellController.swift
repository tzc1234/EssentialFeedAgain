//
//  FeedImageCellController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit
import EssentialFeedAgain

final class FeedImageCellController {
    private(set) var task: Task<Void, Never>?
    
    private let model: FeedImage
    private let imageDataLoader: FeedImageDataLoader
    
    init(model: FeedImage, imageDataLoader: FeedImageDataLoader) {
        self.model = model
        self.imageDataLoader = imageDataLoader
    }
    
    static func registerCellFor(_ tableView: UITableView) {
        tableView.register(FeedImageCell.self, forCellReuseIdentifier: FeedImageCell.cellIdentifier)
    }
    
    func view(for tableView: UITableView) -> FeedImageCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedImageCell.cellIdentifier) as! FeedImageCell
        configure(cell)
        return cell
    }
    
    func configure(_ cell: UITableViewCell) {
        guard let cell = cell as? FeedImageCell else { return }
        
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        cell.feedImageContainer.isShimmering = true
        
        let url = model.url
        let loadImageData: () -> Void = { [weak self] in
            self?.task = Task { @MainActor [weak self, weak cell] in
                defer { cell?.feedImageContainer.isShimmering = false }
                
                guard !Task.isCancelled else { return }
                
                let data = try? await self?.imageDataLoader.loadImageData(from: url)
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.retryButton.isHidden = (image != nil)
            }
        }
        
        cell.onRetry = loadImageData
        loadImageData()
    }
    
    func preloadImageData() {
        let url = model.url
        task = Task { @MainActor [weak self] in
            guard !Task.isCancelled else { return }
            
            _ = try? await self?.imageDataLoader.loadImageData(from: url)
        }
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
        task = nil
    }
    
    deinit {
        cancelImageDataLoad()
    }
}
