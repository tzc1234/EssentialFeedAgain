//
//  FeedSnapshotTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 20/08/2024.
//

import XCTest
@testable import EssentialFeedAgainiOS

final class FeedSnapshotTests: XCTestCase {
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        record(sut.snapshot(for: .iPhone(style: .light)), named: "EMPTY_FEED")
    }
    
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        record(sut.snapshot(for: .iPhone(style: .light)), named: "FEED_WITH_CONTENT")
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> FeedViewController {
        let refresh = FeedRefreshViewController(delegate: DummyFeedRefreshDelegate())
        let sut = FeedViewController(refreshController: refresh)
        FeedImageCellController.registerCellFor(sut.tableView)
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
    
    private func record(_ snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotData = snapshotData(for: snapshot, file: file, line: line)
        let snapshotURL = snapshotURL(name: name, file: file)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try snapshotData?.write(to: snapshotURL)
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

extension UIViewController {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        SnapshotWindow(configuration: configuration, root: self).snapshot()
    }
    
    struct SnapshotConfiguration {
        let size: CGSize
        let safeAreaInsets: UIEdgeInsets
        let layoutMargins: UIEdgeInsets
        let traitCollection: UITraitCollection
        
        static func iPhone(style: UIUserInterfaceStyle, 
                           contentSize: UIContentSizeCategory = .medium) -> SnapshotConfiguration {
            SnapshotConfiguration(
                size: CGSize(width: 390, height: 844),
                safeAreaInsets: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
                layoutMargins: UIEdgeInsets(top: 55, left: 8, bottom: 42, right: 8),
                traitCollection: UITraitCollection(mutations: { traits in
                    traits.forceTouchCapability = .unavailable
                    traits.layoutDirection = .leftToRight
                    traits.preferredContentSizeCategory = contentSize
                    traits.userInterfaceIdiom = .phone
                    traits.horizontalSizeClass = .compact
                    traits.verticalSizeClass = .regular
                    traits.accessibilityContrast = .normal
                    traits.displayScale = 3
                    traits.displayGamut = .P3
                    traits.userInterfaceStyle = style
                })
            )
        }
    }
    
    private final class SnapshotWindow: UIWindow {
        private var configuration: SnapshotConfiguration = .iPhone(style: .light)
        
        convenience init(configuration: SnapshotConfiguration, root: UIViewController) {
            self.init(frame: CGRect(origin: .zero, size: configuration.size))
            self.configuration = configuration
            self.layoutMargins = configuration.layoutMargins
            self.rootViewController = root
            self.isHidden = false
            root.view.layoutMargins = configuration.layoutMargins
        }
        
        override var safeAreaInsets: UIEdgeInsets {
            configuration.safeAreaInsets
        }
        
        override var traitCollection: UITraitCollection {
            configuration.traitCollection
        }
        
        func snapshot() -> UIImage {
            let renderer = UIGraphicsImageRenderer(
                bounds: bounds,
                format: UIGraphicsImageRendererFormat(for: traitCollection)
            )
            return renderer.image { action in
                layer.render(in: action.cgContext)
            }
        }
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
