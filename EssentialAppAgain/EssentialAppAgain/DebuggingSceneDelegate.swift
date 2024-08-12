//
//  DebuggingSceneDelegate.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 12/08/2024.
//

#if DEBUG
import UIKit
import EssentialFeedAgain

final class DebuggingSceneDelegate: SceneDelegate {
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if CommandLine.arguments.contains("-reset") {
            try? FileManager.default.removeItem(at: localStoreURL)
        }
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
    
    override func makeRemoteClient() -> HTTPClient {
        if UserDefaults.standard.string(forKey: "connectivity") == "offline" {
            return AlwaysFailingHTTPClient()
        }
        
        return super.makeRemoteClient()
    }
}

private final class AlwaysFailingHTTPClient: HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        throw NSError(domain: "offline", code: 0)
    }
}
#endif
