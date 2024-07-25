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
    
    @MainActor
    func test_feedImageView_cancelsImageLoadingWhenNotVisibleAnymore() async throws {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, _) = makeSUT(feedStubs: [.success([image0, image1])])
        sut.simulateAppearance()
        
        await sut.completeFeedLoadingTask()
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        let task0 = try XCTUnwrap(sut.imageDataLoadingTask(at: 0))
        let task1 = try XCTUnwrap(sut.imageDataLoadingTask(at: 1))
        
        sut.simulateFeedImageViewNotVisible(for: view0, at: 0)
        XCTAssertTrue(task0.isCancelled)
        XCTAssertFalse(task1.isCancelled)
        
        sut.simulateFeedImageViewNotVisible(for: view1, at: 1)
        XCTAssertTrue(task0.isCancelled)
        XCTAssertTrue(task1.isCancelled)
    }
    
    @MainActor
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() async throws {
        let (sut, _) = makeSUT(feedStubs: [.success([makeImage(), makeImage()])])
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        
        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssertTrue(view0.isShowingLoadingIndicator)
        XCTAssertTrue(view1.isShowingLoadingIndicator)
        
        // A strange behaviour of Task.value (complete a task).
        // There are two imageDataLoadingTasks, when only one imageDataLoadingTask completed,
        // all imageDataLoadingTasks will be completed at once. Cannot complete tasks one by one in a test.
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertFalse(view0.isShowingLoadingIndicator)
        XCTAssertFalse(view1.isShowingLoadingIndicator)
    }
    
    @MainActor
    func test_feedImageView_rendersImageLoadedFromURL() async throws {
        let imageData0 = UIImage.makeData(withColor: .gray)
        let imageData1 = UIImage.makeData(withColor: .red)
        let (sut, _) = makeSUT(
            feedStubs: [.success([makeImage(), makeImage()])],
            imageDataStubs: [.success(imageData0), .success(imageData1)]
        )
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        
        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssertNil(view0.renderedImage)
        XCTAssertNil(view1.renderedImage)
        
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertEqual(view0.renderedImage, imageData0)
        XCTAssertEqual(view1.renderedImage, imageData1)
    }
    
    @MainActor
    func test_feedImageViewRetryButton_isVisibleOnImageLoadError() async throws {
        let imageData = UIImage.makeData(withColor: .gray)
        let (sut, _) = makeSUT(
            feedStubs: [.success([makeImage(), makeImage()])],
            imageDataStubs: [.success(imageData), .failure(anyNSError())]
        )
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        
        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        XCTAssertFalse(view0.isShowingRetryAction)
        XCTAssertFalse(view1.isShowingRetryAction)
        
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertFalse(view0.isShowingRetryAction)
        XCTAssertTrue(view1.isShowingRetryAction)
    }
    
    @MainActor
    func test_feedImageViewRetryButton_isVisibleOnInvalidData() async throws {
        let invalidData = Data("invalid data".utf8)
        let (sut, _) = makeSUT(
            feedStubs: [.success([makeImage()])],
            imageDataStubs: [.success(invalidData)]
        )
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        
        let view = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        XCTAssertFalse(view.isShowingRetryAction)
        
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertTrue(view.isShowingRetryAction)
    }
    
    @MainActor
    func test_feedImageViewRetryAction_retriesImageLoad() async throws {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT(
            feedStubs: [.success([image0, image1])],
            imageDataStubs: [.failure(anyNSError()), .failure(anyNSError())]
        )
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        
        let view0 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulateFeedImageViewVisible(at: 1))
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertEqual(loader.loadImageURLs, [image0.url, image1.url])
        
        view0.simulateRetryAction()
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertEqual(loader.loadImageURLs, [image0.url, image1.url, image0.url])
        
        view1.simulateRetryAction()
        await sut.completeImageDataLoadingTask(at: 1)
        XCTAssertEqual(loader.loadImageURLs, [image0.url, image1.url, image0.url, image1.url])
    }
    
    @MainActor
    func test_feedImageView_preloadsImageURLWhenNearVisible() async {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT(feedStubs: [.success([image0, image1])])
        
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        XCTAssertEqual(loader.loadImageURLs, [])
        
        sut.simulateFeedImageViewNearVisible(at: 0)
        await sut.completeImageDataLoadingTask(at: 0)
        XCTAssertEqual(loader.loadImageURLs, [image0.url])
        
        sut.simulateFeedImageViewNearVisible(at: 1)
        await sut.completeImageDataLoadingTask(at: 1)
        XCTAssertEqual(loader.loadImageURLs, [image0.url, image1.url])
    }
    
    @MainActor
    func test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() async throws {
        let image0 = makeImage(url: URL(string: "https://url-0.com")!)
        let image1 = makeImage(url: URL(string: "https://url-1.com")!)
        let (sut, _) = makeSUT(feedStubs: [.success([image0, image1])])
        sut.simulateAppearance()
        await sut.completeFeedLoadingTask()
        
        sut.simulateFeedImageViewNearVisible(at: 0)
        sut.simulateFeedImageViewNearVisible(at: 1)
        let task0 = try XCTUnwrap(sut.imageDataLoadingTask(at: 0))
        let task1 = try XCTUnwrap(sut.imageDataLoadingTask(at: 1))
        
        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertTrue(task0.isCancelled)
        XCTAssertFalse(task1.isCancelled)
        
        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertTrue(task0.isCancelled)
        XCTAssertTrue(task1.isCancelled)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(feedStubs: [LoaderSpy.FeedStub] = [],
                         imageDataStubs: [LoaderSpy.ImageDataStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy(feedStubs: feedStubs, imageDataStubs: imageDataStubs)
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
        
        init(feedStubs: [FeedStub], imageDataStubs: [ImageDataStub]) {
            self.feedStubs = feedStubs
            self.imageDataStubs = imageDataStubs
        }
        
        func load() async throws -> [FeedImage] {
            loadFeedCallCount += 1
            
            guard !feedStubs.isEmpty else { return [] }
            
            return try feedStubs.removeFirst().get()
        }
        
        // MARK: - FeedImageDataLoader
        
        typealias ImageDataStub = Result<Data, Error>
        
        private(set) var loadImageURLs = [URL]()
        private var imageDataStubs: [ImageDataStub]
        
        @MainActor
        func loadImageData(from url: URL) async throws -> Data {
            loadImageURLs.append(url)
            
            guard !imageDataStubs.isEmpty else { return Data() }
            
            return try imageDataStubs.removeFirst().get()
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
    
    var isShowingLoadingIndicator: Bool {
        feedImageContainer.isShimmering
    }
    
    var renderedImage: Data? {
        feedImageView.image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        !retryButton.isHidden
    }
    
    func simulateRetryAction() {
        retryButton.simulateTap()
    }
}
