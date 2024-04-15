//
//  ItemCover+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Item.Cover {
    /// Parse the image from a Jellyfin item
    static func convertFromJellyfin(imageTags: JellyfinClient.ImageTags, id: String, useLowRes: Bool = false) -> Item.Cover? {
        if let primaryImageTag = imageTags.Primary {
            return Item.Cover(type: .remote, url: constructItemCoverUrl(itemId: id, imageTag: primaryImageTag, size: useLowRes ? 125 : 800))
        }
        
        return nil
    }
    
    /// Construct a valid image URL from an item's ID
    public static func constructItemCoverUrl(itemId: String, imageTag: String?, size: Int = 800, quality: Int = 96) -> URL {
        var query = [
            URLQueryItem(name: "fillHeight", value: String(size)),
            URLQueryItem(name: "fillWidth", value: String(size)),
            URLQueryItem(name: "quality", value: String(quality)),
            URLQueryItem(name: "token", value: JellyfinClient.shared.token),
        ]
        
        if let imageTag = imageTag {
            query.append(URLQueryItem(name: "tag", value: imageTag))
        }
        
        return JellyfinClient.shared.serverUrl.appending(path: "Items").appending(path: itemId).appending(path: "Images").appending(path: "Primary").appending(queryItems: query)
    }
}
