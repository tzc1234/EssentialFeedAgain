//
//  SceneDelegate.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 07/08/2024.
//

import UIKit
import EssentialFeedAgain
import EssentialFeedAgainiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        let url = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let session = URLSession(configuration: .ephemeral)
        let client = URLSessionHTTPClient(session: session)
        let remoteFeedLoader = RemoteFeedLoader(url: url, client: client)
        let remoteImageLoader = RemoteFeedImageDataLoader(client: client)
        
        let feedViewController = FeedUIComposer.feedComposeWith(
            feedLoader: remoteFeedLoader,
            imageDataLoader: remoteImageLoader
        )
        
        window = UIWindow(windowScene: scene)
        window?.rootViewController = feedViewController
        window?.makeKeyAndVisible()
    }
}
