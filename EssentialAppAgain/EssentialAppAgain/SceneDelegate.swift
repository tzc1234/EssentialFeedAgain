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
    
    private let localStoreURL = NSPersistentContainer.defaultDirectoryURL().appending(component: "feed-store.sqlite")
    private lazy var httpClient: HTTPClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    private lazy var store: FeedStore & FeedImageDataStore = try! CoreDataFeedStore(storeURL: localStoreURL)
    
    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore) {
        self.init()
        self.httpClient = httpClient
        self.store = store
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        let url = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
        let remoteFeedLoader = RemoteFeedLoader(url: url, client: httpClient)
        let remoteImageLoader = RemoteFeedImageDataLoader(client: httpClient)
        
        let localFeedLoader = LocalFeedLoader(store: store)
        let localImageDataLoader = LocalFeedImageDataLoader(store: store)
        
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
        window?.rootViewController = UINavigationController(rootViewController: feedViewController)
        window?.makeKeyAndVisible()
    }
}
