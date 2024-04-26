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
        items.map(convert)
    }
    public func convert(item: Item) -> INMediaItem {
        var artist: String?
        
        if let track = item as? Track {
            artist = track.artistName
        } else if let album = item as? Album {
            artist = album.artistName
        }
        
        return INMediaItem(
            identifier: item.id,
            title: item.name,
            type: convertType(type: item.type),
            artwork: convertImage(cover: item.cover),
            artist: artist)
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
