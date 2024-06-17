//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 15.05.24.
//

import Foundation

internal struct JellyfinItem: Codable {
    let Id: String
    let Name: String?
    let SortName: String?
    
    let Overview: String?
    let Genres: [String]?
    
    let ChildCount: Int?
    let RunTimeTicks: UInt64?
    
    let MediaType: String?
    
    let PremiereDate: String?
    let AlbumArtists: [JellyfinArtist]?
    
    let UserData: UserData?
    let ImageTags: ImageTags?
    
    let PlaylistItemId: String?
    
    let IndexNumber: Int?
    let ParentIndexNumber: Int?
    
    let ArtistItems: [JellyfinArtist]?
    
    let Album: String?
    let AlbumId: String?
    
    // TODO: remove
    let AlbumPrimaryImageTag: String?
    
    let LUFS: Float?
    let MediaStreams: [MediaStream]?
}

internal struct JellyfinItemsResponse: Codable {
    let Items: [JellyfinItem]
    let TotalRecordCount: Int
}
