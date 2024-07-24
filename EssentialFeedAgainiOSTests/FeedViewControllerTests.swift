//
//  FeedViewControllerTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 24/07/2024.
//

import XCTest

final class FeedViewController {
    private let loader: FeedViewControllerTests.LoaderSpy
    
    init(loader: FeedViewControllerTests.LoaderSpy) {
        self.loader = loader
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    // MARK: - Helpers
    
    final class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}
