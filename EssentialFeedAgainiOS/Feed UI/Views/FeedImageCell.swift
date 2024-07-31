//
//  FeedImageCell.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import UIKit

public final class FeedImageCell: UITableViewCell {
    public let locationContainer = UIView()
    public let locationLabel = UILabel()
    public let descriptionLabel = UILabel()
    public let feedImageContainer = ShimmeringView()
    public let feedImageView = UIImageView()
    public private(set) lazy var retryButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var onRetry: (() -> Void)?
    var onReuse: ((ObjectIdentifier) -> Void)?
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        onReuse?(ObjectIdentifier(self))
        onReuse = nil
    }
}
