//
//  JellyfinWebSocket.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import Starscream
import OSLog

@Observable
public final class JellyfinWebSocket {
    var socket: WebSocket!
    public internal(set) var connected = false
    
    var reconnectTimeout: UInt64 = 5
    var reconnectTask: Task<(), Error>?
    
    var observedClientId: String?
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "WebSocket")
    
    private init() {}
}

public extension JellyfinWebSocket {
    static let shared = JellyfinWebSocket()
}
