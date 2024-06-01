//
//  ApiError.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

internal extension JellyfinClient {
    struct ClientRequest<T> {
        var path: String
        var method: String
        var body: Any?
        var query: [URLQueryItem]?
        
        var userPrefix = false
        // TODO: can be removed in 10.9
        var userId = false
        
        public init(path: String, method: String, body: Any? = nil, query: [URLQueryItem]? = nil, userPrefix: Bool = false, userId: Bool = false) {
            self.path = path
            self.method = method
            self.body = body
            self.query = query
            self.userPrefix = userPrefix
            self.userId = userId
        }
    }
    
    struct EmptyResponse: Decodable {}
}

public extension JellyfinClient {
    enum ClientError: Error {
        case parseFailed
        case unknownMessage
        
        case invalidServerUrl
        case invalidHttpBody
        case invalidResponse
    }
}
