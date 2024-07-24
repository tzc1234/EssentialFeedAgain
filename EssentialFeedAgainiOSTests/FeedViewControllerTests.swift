//
//  FeedViewControllerTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 24/07/2024.
//

import XCTest
import EssentialFeedAgain
import EssentialFeedAgainiOS

final class FeedViewControllerTests: XCTestCase {
    @MainActor
    func test_loadFeedActions_requestsFeedFromLoader() async {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0)
        
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 1)
        
        sut.simulateUserInitiatedFeedReload()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    @MainActor
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() async {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        await sut.completeFeedLoadingTask()
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        await sut.completeFeedLoadingTask()
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    @MainActor
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() async {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, _) = makeSUT(feedStubs: [
            .success([image0]),
            .success([image0, image1, image2, image3])
        ])
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        await sut.completeFeedLoadingTask()
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        await sut.completeFeedLoadingTask()
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    @MainActor
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() async {
        let image0 = makeImage()
        let (sut, _) = makeSUT(feedStubs: [
            .success([image0]),
            .failure(anyNSError())
        ])
        
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        await sut.completeFeedLoadingTask()
        assertThat(sut, isRendering: [image0])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(feedStubs: [LoaderSpy.FeedStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy(feedStubs: feedStubs)
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: FeedViewController, 
                            isRendering feed: [FeedImage],
                            file: StaticString = #filePath,
                            line: UInt = #line) {
        let actualCount = sut.numberOfRenderedFeedImageView()
        let expectedCount = feed.count
        guard actualCount == expectedCount else {
            return XCTFail("Expected \(expectedCount) images, got \(actualCount) instead", file: file, line: line)
        }
        
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, 
                            hasViewConfiguredFor image: FeedImage,
                            at index: Int,
                            file: StaticString = #filePath,
                            line: UInt = #line) {
        guard let cell = sut.feedImageView(at: index) else {
            return XCTFail("Expected \(FeedImageCell.self) instance", file: file, line: line)
        }
        
        let isLocationVisible = image.location != nil
        XCTAssertEqual(
            cell.isShowingLocation,
            isLocationVisible,
            "Expected `isShowingLocation` to be \(isLocationVisible) for image view at index: \(index)",
            file: file,
            line: line
        )
        
        XCTAssertEqual(
            cell.locationText,
            image.location,
            "Expected location to be \(String(describing: image.location)) for image view at index: \(index)",
            file: file,
            line: line
        )
        
        XCTAssertEqual(
            cell.descriptionText,
            image.description,
            "Expected description to be \(String(describing: image.description)) for image view at index: \(index)",
            file: file,
            line: line
        )
    }
    
    private func makeImage(description: String? = nil,
                           location: String? = nil,
                           url: URL = URL(string: "https://any-url.com")!) -> FeedImage {
        FeedImage(id: UUID(), description: description, location: location, url: url)
    }
    
    private final class LoaderSpy: FeedLoader {
        typealias FeedStub = Result<[FeedImage], Error>
        
        private(set) var loadCallCount = 0
        private var feedStubs: [FeedStub]
        
        init(feedStubs: [FeedStub]) {
            self.feedStubs = feedStubs
        }
        
        func load() async throws -> [FeedImage] {
            loadCallCount += 1
            
            guard !feedStubs.isEmpty else { return [] }
            
            return try feedStubs.removeFirst().get()
        }
    }
}

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
        await loadingTask?.value
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
}

extension FeedImageCell {
    var isShowingLocation: Bool {
        !locationContainer.isHidden
    }
    
    var locationText: String? {
        locationLabel.text
    }
    
    var descriptionText: String? {
        descriptionLabel.text
    }
}
