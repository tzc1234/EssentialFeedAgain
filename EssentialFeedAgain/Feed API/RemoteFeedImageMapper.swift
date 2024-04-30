//
//  RemoteFeedImageMapper.swift
//  EssentialFeedAgain
//
//  Created by Tsz-Lung on 29/04/2024.
//

import Foundation

enum RemoteFeedImageMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedImage]
    }
    
    static func map(from data: Data, response: HTTPURLResponse) throws -> [RemoteFeedImage] {
        guard isOK(response), let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoaderError.invalidData
        }
        
        return root.items
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 200
    }
}
