//
//  NSNotification+Offline.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension OfflineManager {
    static let itemDownloadStatusChanged = Notification.Name.init("io.rfk.music.download.updated")
}
