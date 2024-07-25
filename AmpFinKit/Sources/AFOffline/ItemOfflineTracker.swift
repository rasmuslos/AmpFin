//
//  File.swift
//
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation
import OSLog

@Observable
public final class ItemOfflineTracker {
    let itemId: String
    let itemType: Item.ItemType
    
    var _status: OfflineStatus? = nil
    var token: Any? = nil
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "Item")
    
    init(itemId: String, itemType: Item.ItemType) {
        self.itemId = itemId
        self.itemType = itemType
    }
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

public extension ItemOfflineTracker {
    var status: OfflineStatus {
        get {
            if _status == nil {
                token = NotificationCenter.default.addObserver(forName: OfflineManager.itemDownloadStatusChanged, object: nil, queue: nil) { [weak self] notification in
                    if notification.object as? String == self?.itemId {
                        guard let status = self?.checkOfflineStatus() else {
                            return
                        }
                        
                        if self?._status != status {
                            self?._status = status
                        }
                    }
                }
                
                _status = checkOfflineStatus()
                
                logger.info("Enabled offline tracking for \(self.itemId)")
            }
            
            return _status!
        }
    }
    
    enum OfflineStatus: Equatable {
        case none
        case working
        case downloaded
    }
}

internal extension ItemOfflineTracker {
    func checkOfflineStatus() -> OfflineStatus {
        if itemType == .track {
            return OfflineManager.shared.offlineStatus(trackId: itemId)
        } else if itemType == .album {
            return OfflineManager.shared.offlineStatus(albumId: itemId)
        } else if itemType == .playlist {
            return OfflineManager.shared.offlineStatus(playlistId: itemId)
        }
        
        return .none
    }
}

public extension Item {
    var offlineTracker: ItemOfflineTracker {
        ItemOfflineTracker(itemId: id, itemType: type)
    }
}
