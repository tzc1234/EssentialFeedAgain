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
    
    // MARK: - Helpers
    
    @MainActor
    private func launch(httpClient: HTTPClientStub,
                        store: InMemoryStore) async throws -> FeedViewController {
        let scene = SceneDelegate(httpClient: httpClient, store: store)
        show(scene)
        
        let nav = try XCTUnwrap(scene.window?.rootViewController as? UINavigationController)
        let feed = try XCTUnwrap(nav.topViewController as? FeedViewController)
        feed.simulateAppearance()
        await feed.completeFeedLoadingTask()
        
        return feed
    }
    
    private func show(_ sceneDelegate: SceneDelegate) {
        let session = UISceneSession.initClass()
        let sceneConnectionOptions = UIScene.ConnectionOptions.initClass()
        let scene = UIWindowScene.initClass()
        sceneDelegate.scene(scene, willConnectTo: session, options: sceneConnectionOptions)
    }
    
    private func completeFeedImageViewRendering(on feed: FeedViewController) async {
        await feed.simulateFeedImageViewVisible(at: 0)
        await feed.simulateFeedImageViewVisible(at: 1)
        await feed.completeImageDataLoadingTask(at: 0)
        await feed.completeImageDataLoadingTask(at: 1)
    }
    
    private final class HTTPClientStub: HTTPClient {
        typealias Stub = (URL) async throws -> (Data, HTTPURLResponse)
        
        private let stub: Stub
        
        init(stub: @escaping Stub) {
            self.stub = stub
        }
        
        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            try await stub(url)
        }
        
        static var offline: HTTPClientStub {
            HTTPClientStub(stub: { _ in throw NSError(domain: "offline", code: 0) })
        }
        
        static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            HTTPClientStub(stub: { url in stub(url) })
        }
    }
    
    private final class InMemoryStore: FeedStore, FeedImageDataStore {
        typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)
        
        private var feedCache: CachedFeed?
        private var feedImageDataCache = [URL: Data]()
        
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