//
//  NSNotification+Offline.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation


extension NSNotification {
    static let TrackDownloadStatusChanged = Notification.Name.init("io.rfk.music.download.track.updated")
    static let AlbumDownloadStatusChanged = Notification.Name.init("io.rfk.music.download.album.updated")
}
