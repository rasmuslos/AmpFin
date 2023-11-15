//
//  Connectivity.swift
//  iOS
//
//  Created by Rasmus Krämer on 15.11.23.
//

import Foundation
import WatchConnectivity
import OSLog
import MusicKit

class SessionDelegate: NSObject {
    let logger = Logger(subsystem: "io.rfk.music", category: "Watch connectivity delegate")
    let session: WCSession = .default
    
    override init() {
        super.init()
        
        session.delegate = self
        session.activate()
    }
}

extension SessionDelegate: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.warning("Error while activating watch connectivity session \(session.description): \(error.localizedDescription)")
            return
        }
        
        logger.info("Session \(session.description) activated successfully")
        
        #if os(iOS)
        if JellyfinClient.shared.isAuthorized {
            ConnectivityKit.shared.sendMessage(AuthenticationMessage(
                server: JellyfinClient.shared.serverUrl.absoluteString,
                userId: JellyfinClient.shared.userId,
                token: JellyfinClient.shared.token))
        }
        #endif
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) did deactivate")
    }
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) reachability changed")
    }
}
