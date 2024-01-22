//
//  File.swift
//
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBase
import OSLog

@Observable
public class ItemOfflineTracker {
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

extension ItemOfflineTracker {
    @MainActor
    public var status: OfflineStatus {
        get {
            if _status == nil {
                logger.info("Enabled offline tracking for \(self.itemId)")
                
                token = NotificationCenter.default.addObserver(forName: OfflineManager.itemDownloadStatusChanged, object: nil, queue: nil) { [weak self] notification in
                    if notification.object as? String == self?.itemId {
                        Task.detached { [self] in
                            self?._status = await self?.checkOfflineStatus()
                        }
                    }
                }
                
                _status = checkOfflineStatus()
            }
            
            return _status!
        }
    }
    
    @MainActor
    func checkOfflineStatus() -> OfflineStatus {
        if itemType == .track {
            return OfflineManager.shared.getOfflineStatus(trackId: itemId)
        } else if itemType == .album {
            return OfflineManager.shared.getOfflineStatus(albumId: itemId)
        } else if itemType == .playlist {
            return OfflineManager.shared.getOfflineStatus(playlistId: itemId)
        }
        
        return .none
    }
}

// MARK: Helper

extension ItemOfflineTracker {
    public enum OfflineStatus: Int {
        case none = 0
        case working = 1
        case downloaded = 2
    }
}
