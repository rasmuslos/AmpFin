//
//  JellyfinWebSocket.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import Starscream
import OSLog

public class JellyfinWebSocket {
    var socket: WebSocket!
    var isConnected = false
    
    var reconnectTimeout: UInt64 = 5
    var reconnectTask: Task<(), Error>?
    
    let logger = Logger(subsystem: "io.rfk.music", category: "WebSocket")
}

extension JellyfinWebSocket {
    public func connect() {
        if let serverUrl = JellyfinClient.shared.serverUrl, let token = JellyfinClient.shared.token {
            var request = URLRequest(url: serverUrl.appending(path: "socket").appending(queryItems: [
                URLQueryItem(name: "api_key", value: token),
                URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            ]))
            request.timeoutInterval = 5
            
            socket = WebSocket(request: request)
            socket.delegate = self
            socket.connect()
        }
    }
    
    func reconnect(resetTimer: Bool) {
        if resetTimer {
            reconnectTimeout = 5
        } else {
            reconnectTimeout = min(reconnectTimeout * 2, 60)
        }
        
        logger.info("Reconnecting WebSocket in \(self.reconnectTimeout) seconds")
        socket.disconnect()
        isConnected = false
        
        reconnectTask = Task.detached { [self] in
            try await Task.sleep(nanoseconds: reconnectTimeout * 1_000_000_000)
            logger.info("Attempting WebSocket reconnect")
            
            socket.connect()
        }
    }
}

extension JellyfinWebSocket: WebSocketDelegate {
    public func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
            logger.info("WebSocket connection established")
        case .disconnected(let reason, let code):
            isConnected = false
            logger.info("WebSocket disconnected with reason \"\(reason)\" (\(code))")
            
            reconnect(resetTimer: true)
        case .text(let message):
            logger.info("Received WebSocket message:")
            print(message)
        case .reconnectSuggested:
            reconnect(resetTimer: true)
            break
        case .error(let error):
            reconnect(resetTimer: false)
            
            if let error = error {
                print(error)
            }
            break
        case .cancelled:
            reconnect(resetTimer: false)
            break
        case .peerClosed:
            reconnect(resetTimer: true)
            break
        default:
            break
        }
    }
}

// MARK: Singleton

extension JellyfinWebSocket {
    public static let shared = JellyfinWebSocket()
}
