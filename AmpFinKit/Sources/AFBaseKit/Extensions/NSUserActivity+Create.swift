//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 07.01.24.
//

import Foundation
import Intents

extension NSUserActivity {
    public static func createUserActivity(item: Item) -> NSUserActivity {
        let identifierSuffix: String
        
        if item.type == .track {
            identifierSuffix = "track"
        } else {
            identifierSuffix = "unknown"
        }
        
        let activity = NSUserActivity(activityType: "io.rfk.ampfin.\(identifierSuffix)")
        
        activity.title = item.name
        activity.persistentIdentifier = item.id
        activity.targetContentIdentifier = item.id
        activity.userInfo = [
            "id": item.id,
        ]
        
        activity.isEligibleForHandoff = true
        
        return activity
    }
}
