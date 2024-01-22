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
public class JellyfinWebSocket {
    var socket: WebSocket!
    public private(set) var isConnected = false
    
    var reconnectTimeout: UInt64 = 5
    var reconnectTask: Task<(), Error>?
    
    var observedClientId: String?
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "WebSocket")
}

public extension JellyfinWebSocket {
    func connect() {
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
        
        NotificationCenter.default.post(name: Self.disconnectedNotification, object: nil)
        
        logger.info("Reconnecting WebSocket in \(self.reconnectTimeout) seconds")
        socket.disconnect()
        isConnected = false
        
        reconnectTask = Task.detached { [self] in
            try await Task.sleep(nanoseconds: reconnectTimeout * 1_000_000_000)
            logger.info("Attempting WebSocket reconnect")
            
            socket.connect()
        }
    }
    
    func requestSessionUpdates(clientId: String) {
        observedClientId = clientId
        
        // is this stupid? yes. But it works
        socket.write(string: "{\"MessageType\":\"SessionsStart\",\"Data\":\"100,800\"}")
    }
    func stopReceivingSessionUpdates() {
        observedClientId = nil
        socket.write(string: "{\"MessageType\":\"SessionsStop\"}")
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
            guard let data = message.data(using: .utf8, allowLossyConversion: false) else { throw JellyfinClientError.parseFailed }
            let parsed = try JSONDecoder().decode(Message.self, from: data)
            
            if parsed.MessageType == "ForceKeepAlive" {
                logger.info("Received a \"keep alive\" message from the server")
            } else if parsed.MessageType == "Playstate" {
                let playStateMessage = try JSONDecoder().decode(PlayStateMessage.self, from: data)
                
                NotificationCenter.default.post(name: Self.playStateCommandIssuedNotification, object: nil, userInfo: [
                    "position": playStateMessage.Data?.SeekPositionTicks as Any,
                    "command": playStateMessage.Data?.Command?.lowercased() as Any,
                ])
            } else if parsed.MessageType == "Play" {
                let playMessage = try JSONDecoder().decode(PlayMessage.self, from: data)
                
                NotificationCenter.default.post(name: Self.playCommandIssuedNotification, object: nil, userInfo: [
                    "trackIds": playMessage.Data?.ItemIds as Any,
                    "index": playMessage.Data?.StartIndex as Any,
                    "command": playMessage.Data?.PlayCommand?.lowercased() as Any,
                ])
            } else if parsed.MessageType == "Sessions" {
                let sessionMessage = try JSONDecoder().decode(SessionMessage.self, from: data)
                guard let observedSession = sessionMessage.Data?.filter({ $0.DeviceId == observedClientId }).first else { return }
                
                NotificationCenter.default.post(name: Self.sessionUpdateNotification, object: Session.convertFromJellyfin(observedSession))
            } else {
                throw JellyfinClientError.unknownMessage
            }
        } catch {}
    }
}

// MARK: Singleton

extension JellyfinWebSocket {
    public static let shared = JellyfinWebSocket()
}
