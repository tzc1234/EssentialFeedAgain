//
//  SceneDelegate.swift
//  EssentialAppAgain
//
//  Created by Tsz-Lung on 07/08/2024.
//

import UIKit
import CoreData
import EssentialFeedAgain
import EssentialFeedAgainiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        let url = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let remoteClient = makeRemoteClient()
        let remoteFeedLoader = RemoteFeedLoader(url: url, client: remoteClient)
        let remoteImageLoader = RemoteFeedImageDataLoader(client: remoteClient)
        
        let localStoreURL = NSPersistentContainer.defaultDirectoryURL().appending(component: "feed-store.sqlite")
        let localStore = try! CoreDataFeedStore(storeURL: localStoreURL)
        let localFeedLoader = LocalFeedLoader(store: localStore)
        let localImageDataLoader = LocalFeedImageDataLoader(store: localStore)
        
        if CommandLine.arguments.contains("-reset") {
            try? FileManager.default.removeItem(at: localStoreURL)
        }
        
        let feedViewController = FeedUIComposer.feedComposeWith(
            feedLoader: FeedLoaderWithFallbackComposite(
                primary: FeedLoaderCacheDecorator(
                    decoratee: remoteFeedLoader,
                    cache: localFeedLoader
                ),
                fallback: localFeedLoader),
            imageDataLoader: FeedImageDataLoaderWithFallbackComposite(
                primary: localImageDataLoader,
                fallback: FeedImageDataLoaderCacheDecorator(
                    decoratee: remoteImageLoader,
                    cache: localImageDataLoader
                )
            )
        )
        
        window = UIWindow(windowScene: scene)
        window?.rootViewController = feedViewController
        window?.makeKeyAndVisible()
    }
    
    private func makeRemoteClient() -> HTTPClient {
        switch UserDefaults.standard.string(forKey: "connectivity") {
        case "offline":
            return AlwaysFailingHTTPClient()
        default:
            return URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        }
    }
}

private final class AlwaysFailingHTTPClient: HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        throw NSError(domain: "offline", code: 0)
    }
}
