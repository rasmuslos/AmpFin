//
//  ConnectivityViewModel.swift
//  iOS
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
        
        logger.info("Session \(session.description) activated successfully. Sending authentication data")
        
        if JellyfinClient.shared.isAuthorized {
            session.sendMessage([
                "type": ConnectivityMessageTypes.authentication.rawValue,
                "server": JellyfinClient.shared.serverUrl.absoluteString,
                "userId": JellyfinClient.shared.userId!,
                "token": JellyfinClient.shared.token!,
            ], replyHandler: nil) {
                print($0)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) did deactivate")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("Watch connectivity session \(session.description) reachability changed")
    }
}

extension ConnectivityViewModel {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        logger.info("Received watch connectivity message")
        print(message)
    }
}
