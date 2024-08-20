//
//  FeedViewController.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import SwiftUI
import EssentialFeedAgain

public final class FeedViewController: UITableViewController {
    private let errorViewStore = ErrorContentStore()
    private lazy var errorView = {
        UIHostingConfiguration {
            ErrorView(store: errorViewStore)
        }
        .margins(.all, 0)
        .makeContentView()
    }()
    
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var cellControllers = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }
    
    let refreshController: FeedRefreshViewController
    
    public init(refreshController: FeedRefreshViewController) {
        self.refreshController = refreshController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self
        tableView.refreshControl = refreshController.view
        tableView.separatorStyle = .none
        tableView.tableHeaderView = errorView
        
        onViewIsAppearing = { vc in
            vc.refreshController.refresh()
            vc.onViewIsAppearing = nil
        }
        
        errorViewStore.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.sizeTableHeaderToFit()
            self?.tableView.endUpdates()
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeTableHeaderToFit()
    }
    
    public func display(_ cellControllers: [FeedImageCellController]) {
        self.cellControllers = cellControllers
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

extension FeedViewController: FeedErrorView {
    public func display(_ viewModel: FeedErrorViewModel) {
        errorViewStore.message = viewModel.errorMessage
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
        let delegate = FeedImageCellControllerDelegateStub(viewModel: viewModel)
        let controller = FeedImageCellController(delegate: delegate)
        delegate.cellController = controller
        return controller
    }
    
    feedController.display([
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
    ])
    
    return feedController
}
