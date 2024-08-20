//
//  FeedSnapshotTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 20/08/2024.
//

import XCTest
@testable import EssentialFeedAgain
import EssentialFeedAgainiOS

final class FeedSnapshotTests: XCTestCase {
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        assert(sut.snapshot(for: .iPhone(style: .light)), named: "EMPTY_FEED_light")
        assert(sut.snapshot(for: .iPhone(style: .dark)), named: "EMPTY_FEED_dark")
    }
    
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        assert(sut.snapshot(for: .iPhone(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(sut.snapshot(for: .iPhone(style: .dark)), named: "FEED_WITH_CONTENT_dark")
    }
    
    func test_feedWithErrorMessage() {
        let sut = makeSUT()
        
        sut.display(FeedErrorViewModel(errorMessage: "This is a\nmulti-line\nerror message"))
        
        assert(sut.snapshot(for: .iPhone(style: .light)), named: "FEED_WITH_EERROR_MESSAGE_light")
        assert(sut.snapshot(for: .iPhone(style: .dark)), named: "FEED_WITH_EERROR_MESSAGE_dark")
    }
    
    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()
        
        sut.display(feedWithFailedImageLoading())
        
        assert(sut.snapshot(for: .iPhone(style: .light)), named: "FEED_WITH_FAILED_IMAGE_LOADING_light")
        assert(sut.snapshot(for: .iPhone(style: .dark)), named: "FEED_WITH_FAILED_IMAGE_LOADING_dark")
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> FeedViewController {
        let refresh = FeedRefreshViewController(delegate: DummyFeedRefreshDelegate())
        let sut = FeedViewController(refreshController: refresh)
        FeedImageCellController.registerCellFor(sut.tableView)
        sut.tableView.showsVerticalScrollIndicator = false
        sut.tableView.showsHorizontalScrollIndicator = false
        return sut
    }
    
    private func emptyFeed() -> [FeedImageCellController] {
        []
    }
    
    private func feedWithContent() -> [ImageStub] {
        [
            ImageStub(
                description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                location: "East Side Gallery\nMemorial in Berlin, Germany",
                image: UIImage.make(withColor: .red)),
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: UIImage.make(withColor: .green))
        ]
    }
    
    private func feedWithFailedImageLoading() -> [ImageStub] {
        [
            ImageStub(description: nil, location: "Cannon Street, London", image: nil),
            ImageStub(description: nil, location: "Brighton Seafront", image: nil)
        ]
    }
    
    private func assert(_ snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotData = snapshotData(for: snapshot, file: file, line: line)
        let snapshotURL = snapshotURL(name: name, file: file)
        
        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            XCTFail(
                """
                Failed to load stored snapshot at URL: \(snapshotURL).
                Use the `record` method to store a snapshot before asserting.
                """,
                file: file,
                line: line
            )
            return
        }
        
        if snapshotData != storedSnapshotData {
            let temporarySnapshotURL = URL.temporaryDirectory.appending(component: snapshotURL.lastPathComponent)
            try? snapshotData?.write(to: temporarySnapshotURL)
            
            XCTFail(
                """
                New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL),
                stored snapshot URL: \(snapshotURL)
                """,
                file: file,
                line: line
            )
        }
    }
    
    private func record(_ snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotData = snapshotData(for: snapshot, file: file, line: line)
        let snapshotURL = snapshotURL(name: name, file: file)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try snapshotData?.write(to: snapshotURL)
            XCTFail("Record succeeded - use `assert` to compare the snapshot.", file: file, line: line)
        } catch {
            XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }
    
    private func snapshotData(for snapshot: UIImage, file: StaticString, line: UInt) -> Data? {
        guard let data = snapshot.pngData() else {
            XCTFail("Failed to generate PNG data representation from snapshot", file: file, line: line)
            return nil
        }
        
        return data
    }
    
    private func snapshotURL(name: String, file: StaticString) -> URL {
        URL(filePath: String(describing: file))
            .deletingLastPathComponent()
            .appending(component: "snapshots")
            .appending(component: "\(name).png")
    }
    
    private final class DummyFeedRefreshDelegate: FeedRefreshViewControllerDelegate {
        var task: Task<Void, Never>?
        
        func didRequestFeedRefresh() {}
    }
}

private extension FeedViewController {
    func display(_ stubs: [ImageStub]) {
        let cells: [FeedImageCellController] = stubs.map { stub in
            let cellController = FeedImageCellController(delegate: stub)
            stub.cellController = cellController
            return cellController
        }
        
        display(cells)
    }
}

private final class ImageStub: FeedImageCellControllerDelegate {
    var task: Task<Void, Never>?
    weak var cellController: FeedImageCellController?
    
    private let viewModel: FeedImageViewModel<UIImage>
    
    init(description: String?, location: String?, image: UIImage?) {
        self.viewModel = FeedImageViewModel<UIImage>(
            description: description,
            location: location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil
        )
    }
    
    func loadImageData() {
        cellController?.display(viewModel)
    }
    
    func cancelImageDataLoad() {}
}
