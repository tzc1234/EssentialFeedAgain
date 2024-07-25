//
//  FeedViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit
import EssentialFeedAgain

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) async throws -> Data
}

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
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        onViewIsAppearing = { vc in
            vc.load()
            vc.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    @objc private func load() {
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
        let model = tableModels[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description
        cell.feedImageView.image = nil
        cell.retryButton.isHidden = true
        cell.feedImageContainer.isShimmering = true
        imageDataLoadingTasks[indexPath] = Task { @MainActor [weak self, weak cell] in
            defer { cell?.feedImageContainer.isShimmering = false }
            
            guard let self, !Task.isCancelled else { return }
            
            do {
                let data = try await imageDataLoader.loadImageData(from: model.url)
                let image = UIImage(data: data)
                cell?.feedImageView.image = image
            } catch {
                cell?.retryButton.isHidden = false
            }
        }
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        imageDataLoadingTasks[indexPath]?.cancel()
        imageDataLoadingTasks[indexPath] = nil
    }
}
