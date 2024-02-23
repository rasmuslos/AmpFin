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

    }
    
    struct PlayStateMessage: Codable {
        let Data: MessageData?
        
        struct MessageData: Codable {
            let Command: String?
            let SeekPositionTicks: UInt64?
        }
    }
    struct PlayMessage: Codable {
        let Data: MessageData?
        
        struct MessageData: Codable {
            let ItemIds: [String]?
            let PlayCommand: String?
            let StartIndex: Int?
        }
    }
    
    struct SessionMessage: Codable {
        let Data: [JellyfinClient.JellyfinSession]?
    }
    
    struct GeneralCommandMessage: Codable {
        let Name: String?
        let Arguments: Arguments?
        
        struct Arguments: Codable {
            let RepeatMode: String?
            let ShuffleMode: String?
        }
    }
}
