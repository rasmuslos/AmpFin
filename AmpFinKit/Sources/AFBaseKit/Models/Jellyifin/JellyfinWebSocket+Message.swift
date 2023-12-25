//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

extension JellyfinWebSocket {
    struct Message: Codable {
        let MessageType: String
        let MessageId: String
        let Data: MessageData?
        
        struct MessageData: Codable {
            let ItemIds: [String]?
            let Command: String?
            let PlayCommand: String?
            let SeekPositionTicks: UInt64?
        }
    }
}
