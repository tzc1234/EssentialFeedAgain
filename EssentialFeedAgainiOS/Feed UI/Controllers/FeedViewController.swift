//
//  FeedViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit
import EssentialFeedAgain

public final class FeedViewController: UITableViewController {
    public private(set) var feedLoadingTask: Task<Void, Never>?
    public private(set) var imageDataLoadingTasks = [IndexPath: Task<Void, Never>]()
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var tableModels = [FeedImage]()
    
    private let feedLoader: FeedLoader
    private let imageDataLoader: FeedImageDataLoader
    
    public init(feedLoader: FeedLoader, imageDataLoader: FeedImageDataLoader) {
        self.feedLoader = feedLoader
        self.imageDataLoader = imageDataLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        tableView.register(FeedImageCell.self, forCellReuseIdentifier: FeedImageCell.cellIdentifier)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
        onViewIsAppearing = { vc in
            vc.loadFeed()
            vc.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    @objc private func loadFeed() {
        refreshControl?.beginRefreshing()
        feedLoadingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            if let feed = try? await feedLoader.load() {
                tableModels = feed
            }
            tableView.reloadData()
            refreshControl?.endRefreshing()
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableModels.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedImageCell.cellIdentifier)!
        configure(cell, for: indexPath)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        configure(cell, for: indexPath)
    }
    
    private func configure(_ cell: UITableViewCell, for indexPath: IndexPath) {
        guard let cell = cell as? FeedImageCell else { return }
        
        let model = tableModels[indexPath.row]
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        cell.feedImageContainer.isShimmering = true
        
        let loadImageData: () -> Void = { [weak self] in
            self?.imageDataLoadingTasks[indexPath] = Task { @MainActor [weak self, weak cell] in
                defer { cell?.feedImageContainer.isShimmering = false }
                
                guard !Task.isCancelled else { return }
                
                let data = try? await self?.imageDataLoader.loadImageData(from: model.url)
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.retryButton.isHidden = (image != nil)
            }
        }
        
        cell.onRetry = loadImageData
        loadImageData()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelImageDataLoad(for: indexPath)
    }
    
    private func cancelImageDataLoad(for indexPath: IndexPath) {
        imageDataLoadingTasks[indexPath]?.cancel()
        imageDataLoadingTasks[indexPath] = nil
    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let url = tableModels[indexPath.row].url
            imageDataLoadingTasks[indexPath] = Task { @MainActor [weak self] in
                guard !Task.isCancelled else { return }
                
                _ = try? await self?.imageDataLoader.loadImageData(from: url)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelImageDataLoad)
    }
}
