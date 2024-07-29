//
//  FeedImageCellController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit

final class FeedImageCellController {
    var task: Task<Void, Never>? { viewModel.task }
    
    private let viewModel: FeedImageViewModel<UIImage>
    
    init(viewModel: FeedImageViewModel<UIImage>) {
        self.viewModel = viewModel
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
        
        bind(cell)
    }
    
    private func bind(_ cell: FeedImageCell) {
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        cell.feedImageView.image = nil
        cell.onRetry = viewModel.loadImageData
        
        viewModel.onLoading = { [weak cell] isLoading in
            cell?.feedImageContainer.isShimmering = isLoading
        }
        
        viewModel.onImageLoad = { [weak cell] image in
            cell?.feedImageView.image = image
        }
        
        viewModel.onShouldRetry = { [weak cell] shouldRetry in
            cell?.retryButton.isHidden = !shouldRetry
        }
        
        viewModel.loadImageData()
    }
    
    func preload() {
        viewModel.loadImageData()
    }
    
    func cancelLoad() {
        viewModel.cancelImageDataLoad()
    }
}
