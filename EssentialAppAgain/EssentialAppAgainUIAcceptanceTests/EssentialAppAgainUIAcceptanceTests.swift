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
        XCTAssertEqual(firstCell.imageDescriptionText, "any description")
        XCTAssertEqual(firstCell.locationText, "any location")
        XCTAssertTrue(firstCell.image.exists)
        
        let secondCell = app.feedCell(at: 1)
        XCTAssertFalse(secondCell.imageDescription.exists)
        XCTAssertFalse(secondCell.location.exists)
        XCTAssertTrue(secondCell.image.exists)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let onlineApp = App(state: .online)
        onlineApp.launch()
        
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
    var imageDescription: XCUIElement {
        staticTexts["feed-description"].firstMatch
    }
    
    var imageDescriptionText: String {
        imageDescription.label
    }
    
    var location: XCUIElement {
        staticTexts["feed-location"].firstMatch
    }
    
    var locationText: String {
        location.label
    }
    
    var image: XCUIElement {
        images["feed-image-view"].firstMatch
    }
}
