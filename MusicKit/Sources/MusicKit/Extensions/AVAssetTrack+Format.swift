//
//  AVAssetTrack+Format.swift
//  Music
//
//  Created by Rasmus Krämer on 01.11.23.
//

import Foundation
import AVFoundation

extension AVAssetTrack {
    func getMediaFormat() async -> String? {
        if let descriptions = try? await load(.formatDescriptions), let first = descriptions.first {
            return CMFormatDescriptionGetMediaSubType(first).toString()
        }
        
        return nil
    }
}

extension FourCharCode {
    func toString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}
