//
//  UIImage+TestHelpers.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 25/07/2024.
//

import UIKit
@testable import EssentialFeedAgainiOS

extension UIImage {
    static func makeData(withColor color: UIColor) -> Data {
        make(withColor: color).pngData()!
    }
}
