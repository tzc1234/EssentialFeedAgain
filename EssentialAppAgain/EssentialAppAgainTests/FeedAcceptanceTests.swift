//
//  FeedAcceptanceTests.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 19/08/2024.
//

import XCTest
import EssentialFeedAgain
import EssentialFeedAgainiOS
@testable import EssentialAppAgain

final class FeedAcceptanceTests: XCTestCase {
    @MainActor
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() async throws {
        let feed = try await launch(httpClient: .online(response), store: .empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageView(), 2)
        
        let view0 = try XCTUnwrap(feed.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(feed.simulateFeedImageViewVisible(at: 1))
        await feed.completeImageDataLoadingTask(at: 0)
        await feed.completeImageDataLoadingTask(at: 1)
        
        XCTAssertEqual(view0.renderedImage, makeImageData0())
        XCTAssertEqual(view1.renderedImage, makeImageData1())
    }
    
    @MainActor
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() async throws {
        let shareStore = InMemoryStore.empty
        let onlineFeed = try await launch(httpClient: .online(response), store: shareStore)
        await completeFeedImageViewRendering(on: onlineFeed)
        
        let offlineFeed = try await launch(httpClient: .offline, store: shareStore)
        
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageView(), 2)
        
        let view0 = try XCTUnwrap(offlineFeed.simulateFeedImageViewVisible(at: 0))
        let view1 = try XCTUnwrap(offlineFeed.simulateFeedImageViewVisible(at: 1))
        await offlineFeed.completeImageDataLoadingTask(at: 0)
        
        XCTAssertEqual(view0.renderedImage, makeImageData0())
        XCTAssertEqual(view1.renderedImage, makeImageData1())
    }
    
    @MainActor
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() async throws {
        let offlineFeed = try await launch(httpClient: .offline, store: .empty)
        
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageView(), 0)
    }
    
    @MainActor
    func test_onEnteringBackground_deletesExpiredFeedCache() async throws {
        let store = InMemoryStore.withExpiredFeedCache
        
        await enterBackground(with: store)
        
        XCTAssertNil(store.feedCache)
    }
    
    @MainActor
    func test_onEnteringBackground_keepsNonExpiredFeedCache() async throws {
        let store = InMemoryStore.withNonExpiredFeedCache
        
        await enterBackground(with: store)
        
        XCTAssertNotNil(store.feedCache)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func launch(httpClient: HTTPClientStub,
                        store: InMemoryStore) async throws -> FeedViewController {
        let sceneDelegate = SceneDelegate(httpClient: httpClient, store: store)
        sceneDelegate.showScene()
        
        let nav = try XCTUnwrap(sceneDelegate.window?.rootViewController as? UINavigationController)
        let feed = try XCTUnwrap(nav.topViewController as? FeedViewController)
        feed.simulateAppearance()
        await feed.completeFeedLoadingTask()
        
        return feed
    }
    
    @MainActor
    private func enterBackground(with store: InMemoryStore) async {
        let sceneDelegate = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        let scene = UIWindowScene.initClass()
        sceneDelegate.sceneWillResignActive(scene)
        try? await Task.sleep(for: .seconds(0.02)) // Give a little bit time for cache validation
    }
    
    private func completeFeedImageViewRendering(on feed: FeedViewController) async {
        await feed.simulateFeedImageViewVisible(at: 0)
        await feed.simulateFeedImageViewVisible(at: 1)
        await feed.completeImageDataLoadingTask(at: 0)
        await feed.completeImageDataLoadingTask(at: 1)
    }
    
    private final class InMemoryStore: FeedStore, FeedImageDataStore {
        typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)
        
        private(set) var feedCache: CachedFeed?
        private var feedImageDataCache = [URL: Data]()
        
        init(feedCache: CachedFeed? = nil) {
            self.feedCache = feedCache
        }
        
        func retrieve() async throws -> CachedFeed? {
            feedCache
        }
        
        @MainActor
        func insert(_ feed: [LocalFeedImage], timestamp: Date) async throws {
            feedCache = (feed, timestamp)
        }
        
        @MainActor
        func deleteCachedFeed() async throws {
            feedCache = nil
        }
        
        @MainActor
        func insert(_ data: Data, for url: URL) async throws {
            feedImageDataCache[url] = data
        }
        
        func retrieve(dataFor url: URL) async throws -> Data? {
            feedImageDataCache[url]
        }
        
        static var empty: InMemoryStore {
            InMemoryStore()
        }
        
        static var withExpiredFeedCache: InMemoryStore {
            InMemoryStore(feedCache: ([], .distantPast))
        }
        
        static var withNonExpiredFeedCache: InMemoryStore {
            InMemoryStore(feedCache: ([], .now))
        }
    }
    
    private func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return(makeData(for: url), response)
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.path() {
        case "/image-0":
            return makeImageData0()
        case "/image-1":
            return makeImageData1()
        default:
            return makeFeedData()
        }
    }
    
    private func makeImageData0() -> Data {
        UIImage.makeData(withColor: .red)
    }
    
    private func makeImageData1() -> Data {
        UIImage.makeData(withColor: .green)
    }
    
    private func makeFeedData() -> Data {
        let json: [String: Any] = [
            "items": [
                ["id": UUID().uuidString, "image": "http://feed.com/image-0"],
                ["id": UUID().uuidString, "image": "http://feed.com/image-1"]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
