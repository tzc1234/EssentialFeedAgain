//
//  HTTPClient.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

public protocol HTTPClient {
    typealias Completion = (Result<(Data, HTTPURLResponse), Error>) -> Void
    
    func get(from url: URL, completion: @escaping Completion) -> HTTPClientTask
}

public protocol HTTPClientTask {
    func cancel()
}
