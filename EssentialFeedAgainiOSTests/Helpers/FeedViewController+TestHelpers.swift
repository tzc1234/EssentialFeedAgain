//
//  FeedViewController+TestHelpers.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 25/07/2024.
//

import Foundation
import EssentialFeedAgainiOS

extension FeedViewController {
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
        
        refreshControl = spy
    }
    
    func completeFeedLoadingTask() async {
        await feedLoadingTask?.value
    }
    
    func completeImageDataLoadingTask(at row: Int) async {
        await imageDataLoadingTask(at: row)?.value
    }
    
    func imageDataLoadingTask(at row: Int) -> Task<Void, Never>? {
        let index = IndexPath(row: row, section: feedImagesSection)
        return imageDataLoadingTasks[index]
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedFeedImageView() -> Int {
        tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> FeedImageCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index) as? FeedImageCell
    }
    
    private var feedImagesSection: Int { 0 }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index)
    }
    
    func simulateFeedImageViewNotVisible(for cell: FeedImageCell?, at row: Int) {
        guard let cell else { return }
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: index)
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
}
