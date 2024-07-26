//
//  FeedRefrechViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import UIKit
import EssentialFeedAgain

final class FeedRefreshViewController: NSObject {
    private(set) var loadingTask: Task<Void, Never>?
    
    lazy var view = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    var onRefresh: (([FeedImage]) -> Void)?
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    @objc func refresh() {
        view.beginRefreshing()
        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            if let feed = try? await feedLoader.load() {
                onRefresh?(feed)
            }
            
            view.endRefreshing()
        }
    }
}
