//
//  FeedViewControllerTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 24/07/2024.
//

import XCTest
import UIKit
import EssentialFeedAgain

final class FeedViewController: UITableViewController {
    private(set) var loadingTask: Task<Void, Never>?
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        onViewIsAppearing = { vc in
            vc.refreshControl?.beginRefreshing()
            vc.load()
            vc.onViewIsAppearing = nil
        }
    }
    
    override func viewIsAppearing(_ animated: Bool) {
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

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    @MainActor
    func test_viewAppeared_loadsFeed() async {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        await sut.completeLoadingTask()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    @MainActor
    func test_pullToRefresh_loadsFeed() async {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        sut.refreshControl?.simulatePullToRefresh()
        await sut.completeLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.refreshControl?.simulatePullToRefresh()
        await sut.completeLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    @MainActor
    func test_viewAppeared_showsLoadingIndicator() async {
        let (sut, _) = makeSUT()
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    
    @MainActor
    func test_viewAppeared_hidesLoadingIndicator() async {
        let (sut, _) = makeSUT()
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
        
        await sut.completeLoadingTask()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    
    @MainActor
    func test_pullToRefresh_showsLoadingIndicatorOnLoadingTaskCompletion() async {
        let (sut, _) = makeSUT()
        sut.simulateAppearance()
        await sut.completeLoadingTask()
        
        sut.refreshControl?.simulatePullToRefresh()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private final class LoaderSpy: FeedLoader {
        private(set) var loadCallCount = 0
        
        func load() async throws -> [FeedImage] {
            loadCallCount += 1
            return []
        }
    }
}

extension FeedViewController {
    func completeLoadingTask() async {
        await loadingTask?.value
    }
    
    func simulateAppearance() {
        substituteRefreshControlToSpy()
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func substituteRefreshControlToSpy() {
        let spy = RefreshControlSpy()
        
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                spy.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        
        self.refreshControl = spy
    }
}

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

final class RefreshControlSpy: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool {
        _isRefreshing
    }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}
