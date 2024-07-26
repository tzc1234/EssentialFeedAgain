//
//  FeedViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit
import EssentialFeedAgain

public final class FeedViewController: UITableViewController {
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var cellControllers = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }
    
    let refreshController: FeedRefreshViewController
    private let imageDataLoader: FeedImageDataLoader
    
    public init(feedLoader: FeedLoader, imageDataLoader: FeedImageDataLoader) {
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageDataLoader = imageDataLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        FeedImageCellController.registerCellFor(tableView)
        tableView.refreshControl = refreshController.view
        refreshController.onRefresh = { [weak self] feed in
            guard let self else { return }
            
            cellControllers = feed.map { model in
                FeedImageCellController(model: model, imageDataLoader: self.imageDataLoader)
            }
        }
        onViewIsAppearing = { vc in
            vc.refreshController.refresh()
            vc.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellControllers.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellController(forRowAt: indexPath).view(for: tableView)
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellController(forRowAt: indexPath).configure(cell)
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellController(forRowAt: indexPath).cancelImageDataLoad()
    }
    
    func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        cellControllers[indexPath.row]
    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preloadImageData()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).cancelImageDataLoad()
        }
    }
}
