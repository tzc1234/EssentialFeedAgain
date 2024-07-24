//
//  FeedViewControllerTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 24/07/2024.
//

import XCTest
import UIKit
import EssentialFeedAgain

final class FeedViewController: UIViewController {
    private(set) var loadingTask: Task<Void, Never>?
    
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingTask = Task {
            _ = try? await loader?.load()
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    @MainActor
    func test_viewDidLoad_loadsFeed() async {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        await sut.loadingTask?.value
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private final class LoaderSpy: FeedLoader {
        private(set) var loadCallCount = 0
        
        func load() async throws -> [FeedImage] {
            loadCallCount += 1
            return []
        }
    }
}
