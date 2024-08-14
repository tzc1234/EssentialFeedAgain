//
//  EssentialAppAgainUIAcceptanceTests.swift
//  EssentialAppAgainUIAcceptanceTests
//
//  Created by Tsz-Lung on 12/08/2024.
//

import XCTest

final class EssentialAppAgainUIAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let app = App(state: .online)
        app.launch()
        
        XCTAssertEqual(app.feedCells.count, 2)
        
        let firstCell = app.feedCell(at: 0)
        XCTAssertTrue(firstCell.image.exists)
        
        let secondCell = app.feedCell(at: 1)
        XCTAssertTrue(secondCell.image.exists)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let onlineApp = App(state: .online)
        onlineApp.launch()
        
        let firstFeedImageExists = onlineApp.feedCell(at: 0).image.waitForExistence(timeout: 1)
        let secondFeedImageExists = onlineApp.feedCell(at: 1).image.waitForExistence(timeout: 1)
        XCTAssertTrue(firstFeedImageExists)
        XCTAssertTrue(secondFeedImageExists)
        
        let offlineApp = App(state: .offline(cacheReset: false))
        offlineApp.launch()
        
        XCTAssertEqual(offlineApp.feedCells.count, 2)
        
        let firstCachedImage = offlineApp.feedCell(at: 0).image
        XCTAssertTrue(firstCachedImage.exists)
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let app = App(state: .offline(cacheReset: true))
        
        app.launch()
        
        XCTAssertEqual(app.feedCells.count, 0)
    }
    
    // MARK: - Helpers
    
    private final class App: XCUIApplication {
        enum State {
            case online
            case offline(cacheReset: Bool)
        }
        
        init(state: State) {
            super.init()
            switch state {
            case .online:
                self.launchArguments = ["-reset", "-connectivity", "online"]
            case let .offline(cacheReset):
                self.launchArguments = ["-connectivity", "offline"]
                if cacheReset {
                    self.launchArguments.append("-reset")
                }
            }
        }
        
        var feedCells: XCUIElementQuery {
            cells.matching(identifier: "feed-image-cell")
        }
        
        func feedCell(at index: Int) -> XCUIElement {
            feedCells.element(boundBy: index)
        }
    }
}

private extension XCUIElement {
    var image: XCUIElement {
        images["feed-image-view"].firstMatch
    }
}
