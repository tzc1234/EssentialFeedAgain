//
//  SceneDelegateTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 19/08/2024.
//

import XCTest
import EssentialFeedAgainiOS
@testable import EssentialAppAgain

final class SceneDelegateTests: XCTestCase {
    func test_sceneWillConnectToSession_configuresRootViewController() throws {
        let sut = SceneDelegate()
        
        sut.showScene()
        
        let rootNavigation = try XCTUnwrap(sut.window?.rootViewController as? UINavigationController)
        let topController = rootNavigation.topViewController as? FeedViewController
        XCTAssertNotNil(topController)
    }
}
