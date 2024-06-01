//
//  Track+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFFoundation

internal extension Track {
    convenience init?(_ from: JellyfinItem, fallbackIndex: Int = 0, coverSize: Cover.CoverSize = .normal) {
        guard let albumId = from.AlbumId else {
            return nil
        }
        
        var cover: Cover?
        
        if from.ImageTags!.Primary != nil {
            cover = .init(imageTags: from.ImageTags!, id: from.Id, size: coverSize)
        } else if let imageTag = from.AlbumPrimaryImageTag {
            cover = .init(imageTags: .init(Primary: imageTag), id: albumId, size: coverSize)
        }
        
        var runtime: Double?
        
        if let runTimeTicks = from.RunTimeTicks {
            runtime = Double(runTimeTicks / 10_000_000)
        }
        
        self.init(
            id: from.Id,
            name: from.Name ?? "Unknown Track",
            cover: cover,
            favorite: from.UserData?.IsFavorite ?? false,
            album: ReducedAlbum(
                id: albumId,
                name: from.Album,
                artists: from.AlbumArtists!.map { ReducedArtist(id: $0.Id, name: $0.Name) }
            ),
            artists: from.ArtistItems!.map { ReducedArtist(id: $0.Id, name: $0.Name) },
            lufs: from.LUFS,
            index: Index(index: from.IndexNumber ?? fallbackIndex, disk: from.ParentIndexNumber ?? 1),
            runtime: runtime ?? 0,
            playCount: from.UserData?.PlayCount ?? 0,
            releaseDate: Date(from.PremiereDate))
    }
}
