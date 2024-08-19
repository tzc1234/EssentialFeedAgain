//
//  SceneDelegate+TestHelpers.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 19/08/2024.
//

import UIKit
@testable import EssentialAppAgain

extension SceneDelegate {
    func showScene() {
        let session = UISceneSession.initClass()
        let sceneConnectionOptions = UIScene.ConnectionOptions.initClass()
        let scene = UIWindowScene.initClass()
        self.scene(scene, willConnectTo: session, options: sceneConnectionOptions)
    }
}
