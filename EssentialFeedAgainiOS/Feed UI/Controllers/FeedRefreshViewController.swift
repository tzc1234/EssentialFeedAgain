//
//  FeedRefreshViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit

protocol FeedRefreshViewControllerDelegate {
    var task: Task<Void, Never>? { get }
    
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject {
    var loadingTask: Task<Void, Never>? { delegate.task }
    lazy var view = loadView()
    
    private let delegate: FeedRefreshViewControllerDelegate
    
    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
    }
    
    @objc func refresh() {
        delegate.didRequestFeedRefresh()
    }
    
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}

extension FeedRefreshViewController: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
