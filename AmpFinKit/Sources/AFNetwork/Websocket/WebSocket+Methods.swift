//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 21.05.24.
//

import Foundation
import Starscream

public extension JellyfinWebSocket {
    func connect() {
        guard let serverUrl = JellyfinClient.shared.serverUrl, let token = JellyfinClient.shared._token else {
            return
        }
        
        var request = URLRequest(url: serverUrl.appending(path: "socket").appending(queryItems: [
            URLQueryItem(name: "api_key", value: token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
        ]))
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
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
        connected = false
        
        reconnectTask = Task {
            try await Task.sleep(nanoseconds: reconnectTimeout * NSEC_PER_SEC)
            logger.info("Attempting WebSocket reconnect")
            
            socket.connect()
        }
    }
    
    func beginObservingSessionUpdated(clientId: String) {
        observedClientId = clientId
        socket.write(string: "{\"MessageType\":\"SessionsStart\",\"Data\":\"100,800\"}")
    }
    func stopObservingSessionUpdated() {
        observedClientId = nil
        socket.write(string: "{\"MessageType\":\"SessionsStop\"}")
    }
}
