//
//  FeedImageViewModel.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 30/07/2024.
//

import Foundation

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        location != nil
    }
}
