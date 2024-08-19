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
        
        showScene(on: sut)
        
        let rootNavigation = try XCTUnwrap(sut.window?.rootViewController as? UINavigationController)
        let topController = rootNavigation.topViewController as? FeedViewController
        XCTAssertNotNil(topController)
    }
    
    // MARK: - Helpers
    
    private func showScene(on sut: SceneDelegate) {
        let session = UISceneSession.initClass()
        let sceneConnectionOptions = UIScene.ConnectionOptions.initClass()
        let scene = UIWindowScene.initClass()
        sut.scene(scene, willConnectTo: session, options: sceneConnectionOptions)
    }
}

private extension NSObject {
    static func initClass() -> Self {
        let name = String(describing: Self.self)
        let klass = NSClassFromString(name) as? NSObject.Type
        return klass?.init() as! Self
    }
}
