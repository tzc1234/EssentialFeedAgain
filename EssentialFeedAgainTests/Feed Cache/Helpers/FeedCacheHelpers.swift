//
//  FeedCacheHelpers.swift
//  EssentialFeedAgainTests
//
//  Created by Tsz-Lung on 16/07/2024.
//

import Foundation
import EssentialFeedAgain

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let feed = [uniqueImage(), uniqueImage()]
    let localFeed = feed.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (feed, localFeed)
}

func uniqueImage() -> FeedImage {
    FeedImage(id: UUID(), description: "any description", location: "any location", url: anyURL())
}
