//
//  ApiError.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension JellyfinClient {
    struct ClientRequest<T> {
        var path: String
        var method: String
        var body: Any?
        var query: [URLQueryItem]?
        
        public init(path: String, method: String, body: Any? = nil, query: [URLQueryItem]? = nil) {
            self.path = path
            self.method = method
            self.body = body
            self.query = query
        }
    }
    
    struct EmptyResponse: Decodable {}
}

extension JellyfinClient {
    public static let onlineStatusChanged = Notification.Name.init("io.rfk.ampfin.online.changed")
}

public enum JellyfinClientError: Error {
    case parseFailed
    case unknownMessage
    
    case invalidServerUrl
    case invalidHttpBody
    case invalidResponse
}
