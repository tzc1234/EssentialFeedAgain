//
//  FeedSnapshotTests.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 20/08/2024.
//

import XCTest
import EssentialFeedAgainiOS

final class FeedSnapshotTests: XCTestCase {
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        record(sut.snapshot(for: .iPhone(style: .light)), named: "EMPTY_FEED")
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> FeedViewController {
        let refresh = FeedRefreshViewController(delegate: DummyFeedRefreshDelegate())
        let sut = FeedViewController(refreshController: refresh)
        FeedImageCellController.registerCellFor(sut.tableView)
        sut.simulateAppearance()
        return sut
    }
    
    private func emptyFeed() -> [FeedImageCellController] {
        []
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
    func simulateAppearance() {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
}
