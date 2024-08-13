//
//  EssentialAppAgainUIAcceptanceTests.swift
//  EssentialAppAgainUIAcceptanceTests
//
//  Created by Tsz-Lung on 12/08/2024.
//

import XCTest

final class EssentialAppAgainUIAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let app = XCUIApplication()
        app.launchArguments = ["-reset", "-connectivity", "online"]
        app.launch()
        
        let feedCells = app.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(feedCells.count, 2)
        
        let firstCell = feedCells.firstMatch
        let firstDescription = firstCell.staticTexts["feed-description"].firstMatch
        XCTAssertEqual(firstDescription.label, "any description")
        
        let firstLocation = firstCell.staticTexts["feed-location"].firstMatch
        XCTAssertEqual(firstLocation.label, "any location")
        
        let firstImage = firstCell.images["feed-image-view"].firstMatch
        XCTAssertTrue(firstImage.exists)
        
        let secondCell = feedCells.element(boundBy: 1)
        let secondDescription = secondCell.staticTexts["feed-description"].firstMatch
        let secondLocation = secondCell.staticTexts["feed-location"].firstMatch
        XCTAssertTrue(secondCell.exists)
        XCTAssertFalse(secondDescription.exists)
        XCTAssertFalse(secondLocation.exists)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let onlineApp = XCUIApplication()
        onlineApp.launchArguments = ["-reset", "-connectivity", "online"]
        onlineApp.launch()
        
        let offlineApp = XCUIApplication()
        offlineApp.launchArguments = ["-connectivity", "offline"]
        offlineApp.launch()
        
        let cachedFeedCells = offlineApp.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(cachedFeedCells.count, 2)
        
        let firstCachedImage = offlineApp.images.matching(identifier: "feed-image-view").firstMatch
        XCTAssertTrue(firstCachedImage.exists)
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let app = XCUIApplication()
        app.launchArguments = ["-reset", "-connectivity", "offline"]
        app.launch()
        
        let feedCells = app.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(feedCells.count, 0)
    }
}
