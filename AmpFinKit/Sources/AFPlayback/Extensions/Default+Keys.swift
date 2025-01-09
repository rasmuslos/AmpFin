//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 05.06.24.
//

import Foundation
import Defaults
import AFFoundation

extension Defaults.Keys {
    static let repeatMode = Key("repeatMode", default: RepeatMode.none)
    
    static let maxDownloadBitrate = Key("bitrate_downloads", default: -1)
    static let maxStreamingBitrate = Key("bitrate_streaming", default: -1)
    static let maxConstrainedBitrate = Key("bitrate_constrained", default: -1)
    static let defaultBTDeviceIcon = Key<String>("defaultBTDeviceIcon", default: "hifispeaker")
}
