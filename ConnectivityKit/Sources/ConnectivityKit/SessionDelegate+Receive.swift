//
//  Connectivity+Receive.swift
//  iOS
//
//  Created by Rasmus Krämer on 15.11.23.
//

import Foundation
import WatchConnectivity
import MusicKit

extension SessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let _ = handleMessage(payload: message)
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let message = handleMessage(payload: message) {
            if let reply = message.reply() {
                replyHandler(reply)
            }
        }
    }
    
    func handleMessage(payload: Payload) -> SendableMessage? {
        logger.info("Received watch connectivity message")
        print(payload)
        
        do {
            let message = try Message.parse(payload: payload)
            message.action()
            
            return message
        } catch {
            logger.fault("Failed to parse message")
            print(error)
        }
        
        return nil
    }
}
