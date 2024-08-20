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
        let session = UISceneSession.initFromNSObject()
        let sceneConnectionOptions = UIScene.ConnectionOptions.initFromNSObject()
        let scene = UIWindowScene.initFromNSObject()
        self.scene(scene, willConnectTo: session, options: sceneConnectionOptions)
    }
}
