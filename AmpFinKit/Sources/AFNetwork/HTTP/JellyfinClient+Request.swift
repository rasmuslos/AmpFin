//
//  JellyfinApi+Request.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

internal extension JellyfinClient {
    func request<T: Decodable>(_ clientRequest: ClientRequest<T>) async throws -> T {
        var url: URL
        
        if clientRequest.userPrefix {
            url = serverUrl.appending(path: "Users").appending(path: userId).appending(path: clientRequest.path)
        } else {
            url = serverUrl.appending(path: clientRequest.path)
        }
        
        var query = [
            URLQueryItem(name: "userId", value: userId),
        ]
        
        if let queryItems = clientRequest.query {
            query += queryItems
        }
        
        url = url.appending(queryItems: query)
        
        var request = URLRequest(url: url)
        request.httpMethod = clientRequest.method
        request.timeoutInterval = 15
        
        if let token = _token {
            request.addValue("MediaBrowser Client=\"AmpFin\", Device=\"\(deviceType)\", DeviceId=\"\(clientId)\", Version=\"\(clientVersion)\", Token=\"\(token)\"", forHTTPHeaderField: "X-Emby-Authorization")
        } else {
            request.addValue("MediaBrowser Client=\"AmpFin\", Device=\"\(deviceType)\", DeviceId=\"\(clientId)\", Version=\"\(clientVersion)\", Token=\"\"", forHTTPHeaderField: "X-Emby-Authorization")
        }
        
        if let body = clientRequest.body {
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                logger.fault("Unable to encode body: \(error.localizedDescription)")
                throw ClientError.invalidHttpBody
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
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
                
                if errorCode == .appTransportSecurityRequiresSecureConnection ||
                    errorCode == .callIsActive ||
                    errorCode == .cannotConnectToHost ||
                    errorCode == .cannotFindHost ||
                    errorCode == .cannotLoadFromNetwork ||
                    errorCode == .clientCertificateRejected ||
                    errorCode == .clientCertificateRequired ||
                    errorCode == .dataNotAllowed ||
                    errorCode == .dnsLookupFailed ||
                    errorCode == .internationalRoamingOff ||
                    errorCode == .serverCertificateUntrusted ||
                    errorCode == .serverCertificateHasBadDate ||
                    errorCode == .serverCertificateNotYetValid ||
                    errorCode == .serverCertificateHasUnknownRoot ||
                    errorCode == .secureConnectionFailed ||
                    errorCode == .timedOut {
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
            
            throw ClientError.invalidResponse
        }
    }
}
