//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation

public extension JellyfinWebSocket {
    static let disconnectedNotification = NSNotification.Name("io.rfk.ampfin.socket.disconnect")
    
    static let playCommandIssuedNotification = NSNotification.Name("io.rfk.ampfin.socket.command.play")
    static let playStateCommandIssuedNotification = NSNotification.Name("io.rfk.ampfin.socket.command.playState")
    
    static let sessionUpdateNotification = NSNotification.Name("io.rfk.ampfin.socket.session.update")
}
