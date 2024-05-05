//
//  JellyfinApi+Request.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension JellyfinClient {
    func request<T: Decodable>(_ clientRequest: ClientRequest<T>) async throws -> T {
        var url: URL
        
        if clientRequest.userPrefix {
            url = serverUrl.appending(path: "Users").appending(path: userId).appending(path: clientRequest.path)
        } else {
            url = serverUrl.appending(path: clientRequest.path)
        }
        
        if var query = clientRequest.query {
            if clientRequest.userId {
                query.append(URLQueryItem(name: "userId", value: userId))
            }
            
            url = url.appending(queryItems: query)
        } else if clientRequest.userId {
            url = url.appending(queryItems: [URLQueryItem(name: "userId", value: userId)])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = clientRequest.method
        request.timeoutInterval = 15
        
        if let token = token {
            request.addValue("MediaBrowser Client=\"AmpFin\", Device=\"\(deviceType)\", DeviceId=\"\(clientId)\", Version=\"\(clientVersion)\", Token=\"\(token)\"", forHTTPHeaderField: "X-Emby-Authorization")
        } else {
            request.addValue("MediaBrowser Client=\"AmpFin\", Device=\"\(deviceType)\", DeviceId=\"\(clientId)\", Version=\"\(clientVersion)\", Token=\"\"", forHTTPHeaderField: "X-Emby-Authorization")
        }
        
        if let body = clientRequest.body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                // request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                // print(url, String(data: request.httpBody!, encoding: .ascii))
                
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                logger.fault("Unable to encode body: \(error.localizedDescription)")
                throw JellyfinClientError.invalidHttpBody
            }
        }
        
        // print(request.url?.absoluteString, request.httpMethod, request.allHTTPHeaderFields)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // print(clientRequest.path, String.init(data: data, encoding: .utf8))
            
            if !online {
                online = true
            }
            
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            if let error = error as? URLError {
                let errorCode = error.code
                
                // i guess error codes are combined but i have no idea
                // would be great if the documentation was good
                if errorCode == .appTransportSecurityRequiresSecureConnection || errorCode == .callIsActive || errorCode == .cannotConnectToHost || errorCode == .cannotFindHost || errorCode == .cannotLoadFromNetwork || errorCode == .clientCertificateRejected || errorCode == .clientCertificateRequired || errorCode == .dataNotAllowed || errorCode == .dnsLookupFailed || errorCode == .internationalRoamingOff || errorCode == .serverCertificateUntrusted || errorCode == .serverCertificateHasBadDate || errorCode == .serverCertificateNotYetValid || errorCode == .serverCertificateHasUnknownRoot || errorCode == .secureConnectionFailed || errorCode == .timedOut {
                    logger.fault("Server appears to unreachable while requesting resource \(url): \(error.errorCode) \(error.localizedDescription)")
                    online = false
                } else {
                    logger.fault("Error while requesting resource \(url): \(error.errorCode) \(error.localizedDescription)")
                }
            } else if let error = error as? DecodingError {
                logger.fault("Error while decoding response \(url)")
                print(error)
            } else {
                logger.fault("Unexpected error while requesting resource \(url): \(error.localizedDescription)")
            }
            
            throw JellyfinClientError.invalidResponse
        }
    }
}
