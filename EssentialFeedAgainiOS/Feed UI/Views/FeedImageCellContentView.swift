//
//  FeedImageCellContentView.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 31/07/2024.
//

import SwiftUI

struct FeedImageCellContentView: View {
    let location: String?
    let description: String?
    let image: UIImage?
    let isLoading: Bool
    let shouldRetry: Bool
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let location {
                HStack(alignment: .top, spacing: 6) {
                    Image("pin", bundle: Bundle(for: FeedImageCell.self))
                        .scaledToFit()
                        .padding(.top, 3)
                    
                    Text(location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            ZStack {
                Color(.tertiaryLabel)
                
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                
                Button(action: { onRetry?() }) {
                    Text("↻")
                        .foregroundStyle(.background)
                        .font(.system(size: 75))
                }
                .opacity(shouldRetry ? 1 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .aspectRatio(1, contentMode: .fit)
            .shimmering(active: isLoading)
            
            if let description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Full") {
    FeedImageCellContentView(
        location: "East Side Gallery\nMemorial in Berlin, Germany",
        description: "The East Side Gallery is an open-air gallery in Berlin.", 
        image: .make(withColor: .red),
        isLoading: false,
        shouldRetry: false,
        onRetry: nil
    )
}

#Preview("No Location") {
    FeedImageCellContentView(
        location: nil,
        description: "The East Side Gallery is an open-air gallery in Berlin.", 
        image: .make(withColor: .green),
        isLoading: false,
        shouldRetry: true,
        onRetry: nil
    )
}

#Preview("No Description") {
    FeedImageCellContentView(
        location: "East Side Gallery\nMemorial in Berlin, Germany",
        description: nil,
        image: .make(withColor: .blue),
        isLoading: false,
        shouldRetry: true,
        onRetry: nil
    )
}

#Preview("No Location & Description") {
    FeedImageCellContentView(
        location: nil,
        description: nil,
        image: nil,
        isLoading: false,
        shouldRetry: true,
        onRetry: nil
    )
}

#Preview("Loading") {
    FeedImageCellContentView(
        location: "East Side Gallery\nMemorial in Berlin, Germany",
        description: "The East Side Gallery is an open-air gallery in Berlin.",
        image: nil,
        isLoading: true,
        shouldRetry: false,
        onRetry: nil
    )
}
