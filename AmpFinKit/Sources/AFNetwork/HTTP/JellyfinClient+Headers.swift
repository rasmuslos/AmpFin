//
//  JellyfinClient+Headers.swift
//  AmpFin
// 
// Created by Rasmus Krämer on 03.09.24 at 15:23.
// 

import Foundation

public extension JellyfinClient {
    var customHTTPHeaders: [CustomHTTPHeader] {
        get {
            if let customHTTPHeaders = _customHTTPHeaders {
                return customHTTPHeaders
            }
            
            if let object = Self.defaults.object(forKey: "customHTTPHeaders") as? Data, let headers = try? JSONDecoder().decode([CustomHTTPHeader].self, from: object) {
                _customHTTPHeaders = headers
                return headers
            }
            
            return []
        }
        set {
            _customHTTPHeaders = newValue
            
            if let object = try? JSONEncoder().encode(newValue) {
                Self.defaults.set(object, forKey: "customHTTPHeaders")
            }
        }
    }
    
    var customHTTPHeaderDictionary: [String: String] {
        customHTTPHeaders.reduce(into: [:]) { result, header in
            result[header.key] = header.value
        }
    }
    
    struct CustomHTTPHeader: Codable {
        public var key: String
        public var value: String
        
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
}
