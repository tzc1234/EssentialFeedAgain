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
    
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    @objc private func load() {
        loadingTask = Task {
            _ = try? await loader?.load()
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    @MainActor
    func test_viewDidLoad_loadsFeed() async {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        await sut.completeLoadingTask()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    @MainActor
    func test_pullToRefresh_loadsFeed() async {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        sut.refreshControl?.simulatePullToRefresh()
        await sut.completeLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.refreshControl?.simulatePullToRefresh()
        await sut.completeLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 3)
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
