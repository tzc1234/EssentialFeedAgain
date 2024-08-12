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
        
        app.launch()
        
        let feedCells = app.cells.matching(identifier: "feed-image-cell")
        XCTAssertEqual(feedCells.count, 22)
        
        let firstImage = app.images.matching(identifier: "feed-image-view").firstMatch
        XCTAssertTrue(firstImage.exists)
    }
}
