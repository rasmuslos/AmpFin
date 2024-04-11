//
//  Track+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Track {
    /// Convert an item received from the Jellyfin server into a track type
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinTrackItem, fallbackIndex: Int = 0) throws -> Track {
        guard let albumId = item.AlbumId else { throw JellyfinClientError.invalidResponse }
        
        var cover: Item.Cover?
        
        if item.ImageTags.Primary != nil {
            cover = Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id)
        } else if let imageTag = item.AlbumPrimaryImageTag {
            cover = Cover.convertFromJellyfin(imageTags: JellyfinClient.ImageTags.init(Primary: imageTag), id: albumId)
        }
        
        return Track(
            id: item.Id,
            name: item.Name ?? "",
            cover: cover,
            favorite: item.UserData?.IsFavorite ?? false,
            album: ReducedAlbum(
                id: albumId,
                name: item.Album,
                artists: item.AlbumArtists.map { ReducedArtist(id: $0.Id, name: $0.Name) }
            ),
            artists: item.ArtistItems.map { ReducedArtist(id: $0.Id, name: $0.Name) },
            lufs: item.LUFS,
            index: Index(index: item.IndexNumber ?? fallbackIndex, disk: item.ParentIndexNumber ?? 1),
            runtime: Double(item.RunTimeTicks ?? 0 / 10_000_000),
            playCount: item.UserData?.PlayCount ?? 0,
            releaseDate: Date.parseDate(item.PremiereDate))
    }
    
    // TODO: Remove when 10.9 gets released, as it is not required in this version
    fileprivate struct TrackImage {
        let id: String
        let tag: String
    }
}
