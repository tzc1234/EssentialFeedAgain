//
//  FeedImageCellController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit

protocol FeedImageCellControllerDelegate {
    var task: Task<Void, Never>? { get }
    
    func loadImageData()
    func cancelImageDataLoad()
}

final class FeedImageCellController {
    var task: Task<Void, Never>? { delegate.task }
    private var cell: FeedImageCell?
    
    private let delegate: FeedImageCellControllerDelegate
    
    init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
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
        
        self.cell = cell
        cell.onRetry = delegate.loadImageData
        delegate.loadImageData()
    }
    
    func preload() {
        delegate.loadImageData()
    }
    
    func cancelLoad() {
        delegate.cancelImageDataLoad()
    }
}

extension FeedImageCellController: FeedImageView {
    func display(_ viewModel: FeedImageViewModel<UIImage>) {
        cell?.locationContainer.isHidden = !viewModel.hasLocation
        cell?.locationLabel.text = viewModel.location
        cell?.descriptionLabel.text = viewModel.description
        cell?.feedImageContainer.isShimmering = viewModel.isLoading
        cell?.feedImageView.image = viewModel.image
        cell?.retryButton.isHidden = !viewModel.shouldRetry
    }
}
