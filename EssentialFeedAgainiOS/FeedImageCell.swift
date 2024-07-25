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
    public let retryButton = UIButton()
}
