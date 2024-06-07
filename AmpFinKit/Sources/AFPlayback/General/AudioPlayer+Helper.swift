//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 22.05.24.
//

import Foundation
import AVKit

internal extension AudioPlayer {
    @available(macOS, unavailable)
    static func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    
    @available(macOS, unavailable)
    static func updateAudioSession(active: Bool) {
        do {
            #if !os(macOS)
            try AVAudioSession.sharedInstance().setActive(active)
            #endif
            try AVAudioSession.sharedInstance().setSupportsMultichannelContent(true)
        } catch {
            logger.fault("Failed to update audio session")
        }
        
        #if os(visionOS)
        do {
            try AVAudioSession.sharedInstance().setIntendedSpatialExperience(.fixed(soundStageSize: .large))
        } catch {
            logger.fault("Failed to set immersive soundstage")
        }
        #endif
    }
}
