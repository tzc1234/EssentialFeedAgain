//
//  FeedImageCell.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 24/07/2024.
//

import SwiftUI

public final class FeedImageCell: UITableViewCell {
    public var isShowingLocation: Bool { location != nil }
    public var location: String? {
        didSet { updateLayout() }
    }
    public var imageDescription: String? {
        didSet { updateLayout() }
    }
    public var isLoading = false {
        didSet { updateLayout() }
    }
    public var image: UIImage? {
        didSet { updateLayout() }
    }
    public var shouldRetry = false {
        didSet { updateLayout() }
    }
    
    var onRetry: (() -> Void)? {
        didSet { updateLayout() }
    }
    var onReuse: ((ObjectIdentifier) -> Void)?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        updateLayout()
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func updateLayout() {
        contentConfiguration = UIHostingConfiguration {
            FeedImageCellContentView(
                location: location,
                description: imageDescription,
                image: image,
                isLoading: isLoading,
                shouldRetry: shouldRetry,
                onRetry: onRetry
            )
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        onReuse?(ObjectIdentifier(self))
        onReuse = nil
    }
}

#Preview {
    let cell = FeedImageCell(style: .default, reuseIdentifier: "CELL")
    cell.imageDescription = "The East Side Gallery is an open-air gallery in Berlin."
    cell.location = "East Side Gallery\nMemorial in Berlin, Germany"
    cell.isLoading = true
    cell.shouldRetry = true
    return cell
}
