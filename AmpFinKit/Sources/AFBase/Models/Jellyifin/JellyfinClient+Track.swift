//
//  JellyfinClient+Track.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public extension JellyfinClient {
    struct TracksItemResponse: Codable {
        let Items: [JellyfinTrackItem]
        let TotalRecordCount: Int
    }
    
    struct JellyfinTrackItem: Codable {
        let Id: String
        let PlaylistItemId: String?
        
        let Name: String?
        
        let PremiereDate: String?
        let IndexNumber: Int?
        let ParentIndexNumber: Int?
        
        let UserData: UserData?
        let ArtistItems: [JellyfinArtist]
        
        let Album: String?
        let AlbumId: String?
        let AlbumArtists: [JellyfinArtist]
        
        let ImageTags: ImageTags
        
        // TODO: remove
        let AlbumPrimaryImageTag: String?
        
        let LUFS: Float?
        let RunTimeTicks: UInt64?
        
        let MediaStreams: [MediaStream]?
    }
    
    struct MediaStream: Codable {
        let `Type`: String?
        
        let Codec: String?
        let BitRate: Int?
        let BitDepth: Int?
        let Channels: Int?
        let SampleRate: Int?
    }
}
