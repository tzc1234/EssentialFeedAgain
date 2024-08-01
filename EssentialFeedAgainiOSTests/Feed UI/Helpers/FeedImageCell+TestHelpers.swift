//
//  FeedImageCell+TestHelpers.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 25/07/2024.
//

import Foundation
@testable import EssentialFeedAgainiOS

extension FeedImageCell {
    var locationText: String? {
        location
    }
    
    var descriptionText: String? {
        imageDescription
    }
    
    var isShowingLoadingIndicator: Bool {
        isLoading
    }
    
    var renderedImage: Data? {
        image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        shouldRetry
    }
    
    func simulateRetryAction() {
        onRetry?()
    }
}
