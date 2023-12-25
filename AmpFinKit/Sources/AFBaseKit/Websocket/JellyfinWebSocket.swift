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
            parseMessage(message)
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
    
    func parseMessage(_ message: String) {
        do {
            guard let data = message.data(using: .utf8, allowLossyConversion: false) else { throw JellyfinClientError.invalidHttpBody }
            let parsed = try JSONDecoder().decode(Message.self, from: data)
            
            if parsed.MessageType == "ForceKeepAlive" {
                logger.info("Received keep alive message from server")
            } else if parsed.MessageType == "Playstate" {
                NotificationCenter.default.post(name: Self.playStateCommandIssuedNotification, object: nil, userInfo: [
                    "position": parsed.Data?.SeekPositionTicks as Any,
                    "command": parsed.Data?.Command?.lowercased() as Any,
                ])
            } else if parsed.MessageType == "Play" {
                NotificationCenter.default.post(name: Self.playCommandIssuedNotification, object: nil, userInfo: [
                    "trackIds": parsed.Data?.ItemIds as Any,
                    "command": parsed.Data?.PlayCommand?.lowercased() as Any,
                ])
            } else {
                throw JellyfinClientError.invalidHttpBody
            }
        } catch {}
    }
}

// MARK: Singleton

extension JellyfinWebSocket {
    public static let shared = JellyfinWebSocket()
}
