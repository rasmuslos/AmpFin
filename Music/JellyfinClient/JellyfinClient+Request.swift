//
//  JellyfinApi+Request.swift
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
        
        var userPrefix = false
    }
    
    struct EmptyResponse: Decodable {}
    
    func request<T: Decodable>(_ clientRequest: ClientRequest<T>) async throws -> T {
        var url: URL
        
        if clientRequest.userPrefix {
            url = serverUrl.appending(path: "Users").appending(path: userId).appending(path: clientRequest.path)
        } else {
            url = serverUrl.appending(path: clientRequest.path)
        }
        
        if let query = clientRequest.query {
            url = url.appending(queryItems: query)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = clientRequest.method
        
        if let token = token {
            request.addValue("MediaBrowser Client=\"Music\", Device=\"iOS\", DeviceId=\"\(clientName)\", Version=\"\(clientVersion)\", Token=\"\(token)\"", forHTTPHeaderField: "X-Emby-Authorization")
        } else {
            request.addValue("MediaBrowser Client=\"Music\", Device=\"iOS\", DeviceId=\"\(clientName)\", Version=\"\(clientVersion)\", Token=\"\"", forHTTPHeaderField: "X-Emby-Authorization")
        }
        
        if let body = clientRequest.body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                // print(String(data: request.httpBody!, encoding: .ascii))
                
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                print("Unable to encode body \(error)")
                throw JellyfinClientError.invalidHttpBody
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // print(clientRequest.path, String.init(data: data, encoding: .utf8))
            
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print(error)
            throw JellyfinClientError.invalidResponse
        }
    }
}
