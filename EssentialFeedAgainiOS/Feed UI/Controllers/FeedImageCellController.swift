//
//  FeedImageCellController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit
import EssentialFeedAgain

public protocol FeedImageCellControllerDelegate {
    var task: Task<Void, Never>? { get }
    
    func loadImageData()
    func cancelImageDataLoad()
}

public final class FeedImageCellController {
    var task: Task<Void, Never>? { delegate.task }
    private var cell: FeedImageCell?
    
    private let delegate: FeedImageCellControllerDelegate
    
    public init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }
    
    public static func registerCellFor(_ tableView: UITableView) {
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
        cell.onReuse = { [weak self] id in
            guard let cell = self?.cell, ObjectIdentifier(cell) == id else { return }
            
            self?.releaseCellForReuse()
        }
        delegate.loadImageData()
    }
    
    func preload() {
        delegate.loadImageData()
    }
    
    func cancelLoad() {
        delegate.cancelImageDataLoad()
    }
    
    private func releaseCellForReuse() {
        cell = nil
    }
}

extension FeedImageCellController: FeedImageView {
    public func display(_ viewModel: FeedImageViewModel<UIImage>) {
        cell?.location = viewModel.location
        cell?.imageDescription = viewModel.description
        cell?.isLoading = viewModel.isLoading
        cell?.image = viewModel.image
        cell?.shouldRetry = viewModel.shouldRetry
    }
}
