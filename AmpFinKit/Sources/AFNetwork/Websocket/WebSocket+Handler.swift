//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 21.05.24.
//

import Foundation
import Starscream
import AFFoundation

extension JellyfinWebSocket: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
            case .connected:
                connected = true
                logger.info("WebSocket connection established")
            case .disconnected(let reason, let code):
                connected = false
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
            guard let data = message.data(using: .utf8, allowLossyConversion: false) else {
                throw JellyfinClient.ClientError.parseFailed
            }
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
                
                NotificationCenter.default.post(name: Self.sessionUpdateNotification, object: Session(observedSession))
            } else if parsed.MessageType == "GeneralCommand" {
                let sessionMessage = try JSONDecoder().decode(GeneralCommandMessage.self, from: data)
                
                // this would work if something would work
                
                if sessionMessage.Name == "SetRepeatMode" {
                    NotificationCenter.default.post(name: Self.playStateCommandIssuedNotification, object: nil, userInfo: [
                        "command": "repeatMode",
                        "repeatMode": sessionMessage.Arguments?.RepeatMode as Any,
                    ])
                } else if sessionMessage.Name == "SetShuffleQueue" {
                    NotificationCenter.default.post(name: Self.playStateCommandIssuedNotification, object: nil, userInfo: [
                        "command": "shuffleMode",
                        "shuffleMode": sessionMessage.Arguments?.ShuffleMode as Any,
                    ])
                }
            } else {
                throw JellyfinClient.ClientError.unknownMessage
            }
        } catch {}
    }
}
