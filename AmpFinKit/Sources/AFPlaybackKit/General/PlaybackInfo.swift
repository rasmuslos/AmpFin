//
//  File.swift
//
//
//  Created by Rasmus Krämer on 05.01.24.
//

import Foundation
import AFBaseKit
import Intents

public struct PlaybackInfo {
    let type: PlaybackType
    
    let query: String?
    let container: Item?
    
    var disable = false
    
    public init(type: PlaybackType, query: String?, container: Item?) {
        self.type = type
        self.query = query
        self.container = container
    }
    
    public init(container: Item) {
        switch container.type {
        case .album:
            type = .album
        case .playlist:
            type = .album
        default:
            type = .unknown
        }
        
        query = nil
        self.container = container
    }
    
    public init(disable: Bool) {
        self.init(type: .unknown, query: nil, container: nil)
        self.disable = true
        
        if !disable {
            print("fuck you")
        }
    }
    
    public init() {
        self.init(type: .unknown, query: nil, container: nil)
    }
    
    public enum PlaybackType {
        case album
        case playlist
        case search
        case tracks
        case mix
        case unknown
    }
}

extension PlaybackInfo {
    func donate(nowPlaying: Track, shuffled: Bool, repeatMode: RepeatMode, resumePlayback: Bool) {
        if disable { return }
        
        var inContainer: INMediaItem?
        
        if let container = container {
            var image: INImage?
            var artist: String?
            
            if let cover = container.cover, let data = try? Data(contentsOf: cover.url) {
                image = INImage(imageData: data)
            }
            if let album = container as? Album {
                artist = album.artistName
            }
            
            inContainer = INMediaItem(
                identifier: container.id,
                title: container.name,
                type: container.type == .album ? .album : container.type == .playlist ? .playlist : .unknown,
                artwork: image,
                artist: artist)
        }
        
        var image: INImage?
        if let cover = nowPlaying.cover, let data = try? Data(contentsOf: cover.url) {
            image = INImage(imageData: data)
        }
        
        let intent = INPlayMediaIntent(
            mediaItems: [
                INMediaItem(
                    identifier: nowPlaying.id,
                    title: nowPlaying.name,
                    type: .song,
                    artwork: image,
                    artist: nowPlaying.artistName)
            ],
            mediaContainer: inContainer,
            playShuffled: shuffled,
            playbackRepeatMode: repeatMode == .queue ? .all : repeatMode == .track ? .one : .none,
            resumePlayback: resumePlayback,
            playbackQueueLocation: .unknown,
            playbackSpeed: 1, mediaSearch: INMediaSearch(mediaName: query))
        
        let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: .createUserActivity(item: nowPlaying)))
        interaction.donate()
    }
}
