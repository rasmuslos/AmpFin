//
//  MediaResolver+Convert.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import Intents
import AFFoundation

@available(macOS, unavailable)
public extension MediaResolver {
    func convert(items: [Item]) async -> [INMediaItem] {
        await items.parallelMap(convert)
    }
    func convert(item: Item) async -> INMediaItem {
        var artist: String?
        
        if let track = item as? Track {
            artist = track.artistName
        } else if let album = item as? Album {
            artist = album.artistName
        }
        
        return INMediaItem(
            identifier: item.id,
            title: item.name,
            type: convert(type: item.type),
            artwork: await convert(cover: item.cover),
            artist: artist)
    }
}

@available(macOS, unavailable)
private extension MediaResolver {
    func convert(type: Item.ItemType) -> INMediaItemType {
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
    
    func convert(cover: Cover?) async -> INImage? {
        guard let cover = cover else {
            return nil
        }
        
        if cover.type == .local {
            return INImage(url: cover.url)
        }
        
        guard let data = try? Data(contentsOf: cover.url) else {
            return nil
        }
        
        return INImage(imageData: data)
    }
}
