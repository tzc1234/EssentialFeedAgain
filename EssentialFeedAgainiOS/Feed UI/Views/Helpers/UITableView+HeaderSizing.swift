//
//  UITableView+HeaderSizing.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 20/08/2024.
//

import UIKit

extension UITableView {
    func sizeTableHeaderToFit() {
        guard let header = tableHeaderView else { return }
        
        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        let shouldFrameUpdate = header.frame.height != size.height
        if shouldFrameUpdate {
            header.frame.size.height = size.height
            tableHeaderView = header
        }
    }
}
