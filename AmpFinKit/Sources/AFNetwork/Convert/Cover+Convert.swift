//
//  ItemCover+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFFoundation

extension Cover {
    internal init?(imageTags: ImageTags, id: String, size: CoverSize = .normal) {
        guard let primaryImageTag = imageTags.Primary else {
            return nil
        }
        
        self.init(type: .remote, size: size, url: Self.url(itemId: id, imageTag: primaryImageTag, size: size))
    }
    
    public static func url(itemId: String, imageTag: String?, size: CoverSize = .normal, quality: Int = 96) -> URL {
        let dimensions = String(size.dimensions)
        var query = [
            URLQueryItem(name: "fillHeight", value: dimensions),
            URLQueryItem(name: "fillWidth", value: dimensions),
            
            URLQueryItem(name: "quality", value: String(quality)),
            URLQueryItem(name: "token", value: JellyfinClient.shared.token),
        ]
        
        if let imageTag = imageTag {
            query.append(URLQueryItem(name: "tag", value: imageTag))
        }
        
        return JellyfinClient.shared.serverUrl.appending(path: "Items").appending(path: itemId).appending(path: "Images").appending(path: "Primary").appending(queryItems: query)
    }
}
