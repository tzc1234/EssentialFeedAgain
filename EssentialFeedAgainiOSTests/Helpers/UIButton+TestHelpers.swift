//
//  UIButton+TestHelpers.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 25/07/2024.
//

import UIKit

extension UIButton {
    func simulateTap() {
        simulate(.touchUpInside)
    }
}
