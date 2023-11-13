//
//  NSNotification+Offline.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension OfflineManager {
    static let trackDownloadStatusChanged = Notification.Name.init("io.rfk.music.download.track.updated")
    static let albumDownloadStatusChanged = Notification.Name.init("io.rfk.music.download.album.updated")
}
