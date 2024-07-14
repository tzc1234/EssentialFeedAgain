//
//  HTTPClient.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
