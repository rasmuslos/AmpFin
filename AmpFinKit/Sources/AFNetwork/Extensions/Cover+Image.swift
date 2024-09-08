//
//  Cover+Image.swift
//  AmpFin
// 
// Created by Rasmus Krämer on 03.09.24 at 15:31.
// 
    
import Foundation
import AFFoundation

#if canImport(UIKit)
import UIKit
#endif

public extension Cover {
    var systemImage: PlatformImage? {
        get async {
            var request = URLRequest(url: url)
            
            for header in JellyfinClient.shared.customHTTPHeaders {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            guard let (data, _) = try? await URLSession.shared.data(for: request) else {
                return nil
            }
            
            return PlatformImage(data: data)
        }
    }
    
    #if canImport(UIKit)
    typealias PlatformImage = UIImage
    #endif
}
