//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import MediaPlayer
import Defaults

internal extension LocalAudioEndpoint {
    func setupObservers() {
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            self.nowPlaying = nil
        }
        #endif
        
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        volumeSubscription = AVAudioSession.sharedInstance().publisher(for: \.outputVolume).sink { volume in
            self.systemVolume = volume
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: nil) { [self] notification in
            guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
                case .began:
                    playing = false
                case .ended:
                    guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    
                    if options.contains(.shouldResume) {
                        playing = true
                    }
                default: ()
            }
        }
        #endif
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil) { _ in
            NotificationCenter.default.post(name: AudioPlayer.routeDidChangeNotification, object: nil)
        }
        
        // MARK: Audio-Player
        
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
            
            updateNowPlayingWidget()
            updatePlaybackReporter(scheduled: true)
            
            // Only check isPlaybackLikelyToKeepUp will not be enough because this value will return false
            // when the buffer is full and the playback time is not able to statistically predict if the playback can keep up
            // When current item is not even playing, checking buffering will cause false positives
            if let playItem = audioPlayer.currentItem, playing {
                // We have to check buffer empty first because Apple thinks it is valid to have
                // isPlaybackBufferEmpty == true and isPlaybackBufferFull == true at the same time
                if playItem.isPlaybackBufferEmpty {
                    buffering = true
                } else if playItem.isPlaybackLikelyToKeepUp || playItem.isPlaybackBufferFull {
                    buffering = false
                } else {
                    // The buffer has something, not full, but unlikely to keep up
                    // Uncommon for music files, but added for completeness
                    buffering = true
                }
            } else {
                buffering = false
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [self] _ in
            if repeatMode == .track {
                currentTime = 0
                playing = true
            } else {
                advance(advanceAudioPlayer: false)
            }
        }
        
        // MARK: Bitrate changes
        
        Task {
            for await bitrate in Defaults.updates(.maxStreamingBitrate) {
                logger.info("Maximum streaming bitrate changed to \(bitrate) Kb/s")
                determineBitrate()
            }
        }
        Task {
            for await bitrate in Defaults.updates(.maxConstrainedBitrate) {
                logger.info("Maximum constrained bitrate changed to \(bitrate) Kb/s")
                determineBitrate()
            }
        }
    }
}
