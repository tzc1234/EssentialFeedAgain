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
        if let connectivity = UserDefaults.standard.string(forKey: "connectivity") {
            return DebuggingHTTPClient(connectivity: connectivity)
        }
        
        return super.makeRemoteClient()
    }
}

private final class DebuggingHTTPClient: HTTPClient {
    private let connectivity: String
    
    init(connectivity: String) {
        self.connectivity = connectivity
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        switch connectivity {
        case "online":
            return makeSuccessfulResponse(for: url)
        default:
            throw NSError(domain: "offline", code: 0)
        }
    }
    
    private func makeSuccessfulResponse(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return(makeData(for: url), response)
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.absoluteString {
        case "http://image.com":
            return makeImageData()
        default:
            return makeFeedData()
        }
    }
    
    private func makeImageData() -> Data {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let image = UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            UIColor.red.setFill()
            rendererContext.fill(rect)
        }
        return image.pngData()!
    }
    
    private func makeFeedData() -> Data {
        let json: [String: Any] = [
            "items": [
                ["id": UUID().uuidString, "image": "http://image.com"],
                ["id": UUID().uuidString, "image": "http://image.com"]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
#endif
