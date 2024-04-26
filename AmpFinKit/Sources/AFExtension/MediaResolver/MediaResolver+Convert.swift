//
//  MediaResolver+Convert.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import Intents
import AFBase

extension MediaResolver {
    public func convert(items: [Item]) -> [INMediaItem] {
        items.map {
            var artist: String?
            
            if let track = $0 as? Track {
                artist = track.artistName
            } else if let album = $0 as? Album {
                artist = album.artistName
            }
            
            return INMediaItem(
                identifier: $0.id,
                title: $0.name,
                type: convertType(type: $0.type),
                artwork: convertImage(cover: $0.cover),
                artist: artist)
        }
    }
    
    private func convertType(type: Item.ItemType) -> INMediaItemType {
        switch type {
            case .album:
                return .album
            case .artist:
                return .artist
            case .track:
                return .song
            case .playlist:
                return .playlist
        }
    }
    
    private func convertImage(cover: Item.Cover?) -> INImage? {
        guard let cover = cover else { return nil }
        
        if cover.type == .local {
            return INImage(url: cover.url)
        }
        
        if let data = try? Data(contentsOf: cover.url) {
            return INImage(imageData: data)
        }
        
        return nil
    }
}
