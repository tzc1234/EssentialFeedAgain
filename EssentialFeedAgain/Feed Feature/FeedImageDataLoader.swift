//
//  FeedImageDataLoader.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 26/07/2024.
//

import Foundation

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) async throws -> Data
}
