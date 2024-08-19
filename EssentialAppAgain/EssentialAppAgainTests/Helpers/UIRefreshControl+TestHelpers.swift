//
//  UIRefreshControl+TestHelpers.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(.valueChanged)
    }
}
