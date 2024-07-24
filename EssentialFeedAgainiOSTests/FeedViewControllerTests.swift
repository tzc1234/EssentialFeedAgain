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
        XCTAssertEqual(loader.loadFeedCallCount, 0)
        
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadFeedCallCount, 1)
        
        sut.simulateUserInitiatedFeedReload()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadFeedCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadFeedCallCount, 3)
    }
    
    @MainActor
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() async {
        let (sut, _) = makeSUT(feedStubs: [
            .success([]),
            .failure(anyNSError())
        ])
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        await sut.completeFeedLoadingTask()
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator completed successfully")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        await sut.completeFeedLoadingTask()
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator completed with an error")
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
    
    @MainActor
    func test_feedImageView_loadsImageURLWhenVisible() async {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT(feedStubs: [.success([image0, image1])])
        sut.simulateAppearance()
        
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadImageURLs, [])
        
        sut.simulateFeedImageViewVisible(at: 0)
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertEqual(loader.loadImageURLs, [image0.url])
        
        sut.simulateFeedImageViewVisible(at: 1)
        await sut.completeImageDataLoadingTask(at: 1)
        XCTAssertEqual(loader.loadImageURLs, [image0.url, image1.url])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(feedStubs: [LoaderSpy.FeedStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy(feedStubs: feedStubs)
        let sut = FeedViewController(feedLoader: loader, imageDataLoader: loader)
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
    
    private final class LoaderSpy: FeedLoader, FeedImageDataLoader {
        // MARK: - FeedLoader
        
        typealias FeedStub = Result<[FeedImage], Error>
        
        private(set) var loadFeedCallCount = 0
        private var feedStubs: [FeedStub]
        
        init(feedStubs: [FeedStub]) {
            self.feedStubs = feedStubs
        }
        
        func load() async throws -> [FeedImage] {
            loadFeedCallCount += 1
            
            guard !feedStubs.isEmpty else { return [] }
            
            return try feedStubs.removeFirst().get()
        }
        
        // MARK: - FeedImageDataLoader
        
        private(set) var loadImageURLs = [URL]()
        
        func loadImageData(from url: URL) async {
            loadImageURLs.append(url)
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
        await feedLoadingTask?.value
    }
    
    func completeImageDataLoadingTask(at index: Int) async {
        await imageDataLoadingTasks[index]?.value
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
    
    func simulateFeedImageViewVisible(at index: Int) {
        _ = feedImageView(at: index)
    }
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
