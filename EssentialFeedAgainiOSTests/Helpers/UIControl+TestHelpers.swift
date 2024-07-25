//
//  UIControl+TestHelpers.swift
//  EssentialFeedAgainiOSTests
//
//  Created by Tsz-Lung on 25/07/2024.
//

import UIKit

extension UIControl {
    func simulate(_ event: UIControl.Event) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: event)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
