//
//  ConnectivityViewModel.swift
//  watchOS
//
//  Created by Rasmus Krämer on 13.11.23.
//

import Foundation
import WatchConnectivity
import OSLog
import MusicKit

class ConnectivityViewModel: NSObject {
    let logger = Logger(subsystem: "io.rfk.music", category: "Watch Connectivity")
    let session: WCSession = .default
    
    override init() {
        super.init()
        
        session.delegate = self
        session.activate()
        
        logger.info("Created connectivity view model")
    }
}

extension ConnectivityViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.warning("Error while activating watch connectivity session \(session.description): \(error.localizedDescription)")
            return
        }
        
        logger.info("Session \(session.description) activated successfully")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) reachability changed")
    }
}

extension ConnectivityViewModel {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        logger.info("Received watch connectivity message")
        print(message)
        
        if let code = message["type"] as? Int, let type = ConnectivityMessageTypes(rawValue: code) {
            if type == ConnectivityMessageTypes.authentication {
                if let server = message["server"] as? String, let userId = message["userId"] as? String, let token = message["token"] as? String {
                    try! JellyfinClient.shared.setServerUrl(server)
                    JellyfinClient.shared.setUserId(userId)
                    JellyfinClient.shared.setToken(token)
                }
            }
        }
    }
}
