//
//  Connectivity+Message.swift
//  iOS
//
//  Created by Rasmus Krämer on 15.11.23.
//

import Foundation

// MARK: Types

typealias Payload = [String: Any]

enum MessageType: Int {
    case authentication = 1
}

enum ConnectivityError: Error {
    case parseFailed
    case unknownType
}

// MARK: Protocol

protocol SendableMessage: ConnectivityMessage {
    func getMessage() -> Message
    func action()
    
    static func parse(payload: Payload) throws -> Self
}

extension SendableMessage {
    func replyHandler(payload: Payload) {
    }
    
    func reply() -> Payload? {
        nil
    }
}

// make the protocol public but keep everything in it internal
public protocol ConnectivityMessage {
}

// MARK: Message

struct Message {
    private let type: MessageType
    private let payload: Payload
    
    init(type: MessageType, payload: Payload) {
        self.type = type
        self.payload = payload
    }
    
    func getPayload() -> Payload {
        var payload = payload
        payload["type"] = type.rawValue
        
        return payload
    }
    static func parse(payload: Payload) throws -> SendableMessage {
        if let code = payload["type"] as? Int, let type = MessageType(rawValue: code) {
            switch type {
            case .authentication:
                return try AuthenticationMessage.parse(payload: payload)
            }
        }
        
        throw ConnectivityError.unknownType
    }
}
