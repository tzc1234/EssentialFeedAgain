//
//  FeedRefrechViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit

final class FeedRefreshViewController: NSObject {
    var loadingTask: Task<Void, Never>? { viewModel.task }
    lazy var view = bound(UIRefreshControl())
    
    private let viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func bound(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoading = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
