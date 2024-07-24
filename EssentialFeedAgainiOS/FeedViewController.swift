//
//  FeedViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit
import EssentialFeedAgain

public final class FeedViewController: UITableViewController {
    public private(set) var loadingTask: Task<Void, Never>?
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    
    private var loader: FeedLoader?
    
    public convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
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
        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            _ = try? await loader?.load()
            refreshControl?.endRefreshing()
        }
    }
}
