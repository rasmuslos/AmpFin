//
//  ConnectivityKit.swift
//
//
//  Created by Rasmus Krämer on 15.11.23.
//

import Foundation
import OSLog

public struct ConnectivityKit {
    let logger = Logger(subsystem: "io.rfk.music", category: "Watch connectivity")
    let delegate = SessionDelegate()
    
    // this is stupid but required for the singleton
    public func setup() {
        logger.info("Watch connectivity is now ready")
    }
}

// MARK: Send

public extension ConnectivityKit {
    func sendMessage(_ message: ConnectivityMessage) {
        // this is stupid
        if let message = message as? SendableMessage {
            let sendable = message.getMessage()
            
            delegate.session.sendMessage(sendable.getPayload(), replyHandler: message.replyHandler) {
                self.logger.fault("Error while sending watch message")
                print($0)
            }
        }
    }
}

// MARK: Singleton

public extension ConnectivityKit {
    static let shared = ConnectivityKit()
}
