//
//  UITableViewCell+CellIdentifier.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 25/07/2024.
//

import UIKit

extension UITableViewCell {
    static var cellIdentifier: String {
        String(describing: Self.self)
    }
}
