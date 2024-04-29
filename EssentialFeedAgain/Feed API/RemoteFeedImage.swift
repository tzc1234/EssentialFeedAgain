//
//  RemoteFeedImage.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

struct RemoteFeedImage: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
