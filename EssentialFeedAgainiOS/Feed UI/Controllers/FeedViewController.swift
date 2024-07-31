//
//  FeedViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit

public final class FeedViewController: UITableViewController {
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    var cellControllers = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }
    
    let refreshController: FeedRefreshViewController
    
    init(refreshController: FeedRefreshViewController) {
        self.refreshController = refreshController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        tableView.refreshControl = refreshController.view
        tableView.separatorStyle = .none
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
        cellController(forRowAt: indexPath).cancelLoad()
    }
    
    func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        cellControllers[indexPath.row]
    }
}

extension FeedViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).cancelLoad()
        }
    }
}

#Preview {
    final class DummyRefreshDelegate: FeedRefreshViewControllerDelegate {
        var task: Task<Void, Never>?
        func didRequestFeedRefresh() {}
    }
    
    final class FeedImageCellControllerDelegateStub: FeedImageCellControllerDelegate {
        var task: Task<Void, Never>?
        weak var cellController: FeedImageCellController?
        private let viewModel: FeedImageViewModel<UIImage>
        
        init(viewModel: FeedImageViewModel<UIImage>) {
            self.viewModel = viewModel
        }
        
        func loadImageData() {
            cellController?.display(viewModel)
        }
        
        func cancelImageDataLoad() {}
    }
    
    let refreshController = FeedRefreshViewController(delegate: DummyRefreshDelegate())
    let feedController = FeedViewController(refreshController: refreshController)
    FeedImageCellController.registerCellFor(feedController.tableView)
    
    func makeCellController(by viewModel: FeedImageViewModel<UIImage>) -> FeedImageCellController {
        let cellControllerDelegateStub = FeedImageCellControllerDelegateStub(viewModel: viewModel)
        let cellController = FeedImageCellController(delegate: cellControllerDelegateStub)
        cellControllerDelegateStub.cellController = cellController
        return cellController
    }
    
    feedController.cellControllers = [
        makeCellController(by: FeedImageViewModel(
            description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
            location: "East Side Gallery\nMemorial in Berlin, Germany",
            image: nil,
            isLoading: true,
            shouldRetry: false
        )),
        makeCellController(by: FeedImageViewModel(
            description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
            location: "Garth Pier",
            image: .make(withColor: .red),
            isLoading: false,
            shouldRetry: false
        )),
        makeCellController(by: FeedImageViewModel(
            description: nil,
            location: nil,
            image: nil,
            isLoading: false,
            shouldRetry: true
        ))
    ]
    
    return feedController
}
