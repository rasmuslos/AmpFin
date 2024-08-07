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
    func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            updatePlaybackReporter(scheduled: true)
            
            // Only check isPlaybackLikelyToKeepUp will not be enough because this value will return false
            // when the buffer is full and the playback time is not able to statistically predict if the playback can keep up
            // When current item is not even playing, checking buffering will cause false positives
            let buffering: Bool
            
            if let playItem = audioPlayer.currentItem, playing {
                // We have to check buffer empty first because Apple thinks it is valid to have
                // isPlaybackBufferEmpty == true and isPlaybackBufferFull == true at the same time
                if playItem.isPlaybackBufferEmpty {
                    buffering = true
                } else if playItem.isPlaybackLikelyToKeepUp || playItem.isPlaybackBufferFull {
                    buffering = false
                } else {
                    // The buffer has something, not full, but unlikely to keepup
                    // Uncommon for music files, but added for completeness
                    buffering = true
                }
            } else {
                buffering = false
            }
            
            if self.buffering != buffering {
                self.buffering = buffering
            }
            
            let playing = audioPlayer.rate > 0
            if self.playing != playing {
                _playing = playing
            }
            
            _currentTime = audioPlayer.currentTime().seconds
            duration = audioPlayer.currentItem?.duration.seconds ?? 0
        }
    }
    func setupObservers() {
        // The player is never discarded, so no removing of the observers is necessary
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [self] _ in
            if repeatMode == .track {
                currentTime = 0
                playing = true
            } else {
                if !avPlayerQueue.isEmpty {
                    avPlayerQueue.removeFirst()
                }
                
                trackDidFinish()
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil) { _ in
            Task { @MainActor in
                self.outputRoute = Self.audioRoute()
            }
        }
        
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        volumeSubscription = AVAudioSession.sharedInstance().publisher(for: \.outputVolume).sink { volume in
            Task { @MainActor [volume] in
                self._volume = volume
            }
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
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            self.setNowPlaying(track: nil)
        }
        #endif
        
        Task {
            for await bitrate in Defaults.updates(.maxStreamingBitrate) {
                logger.info("Maximum streaming bitrate changed to \(bitrate) Kb/s")
                await bitrateDidChange()
            }
        }
        Task {
            for await bitrate in Defaults.updates(.maxConstrainedBitrate) {
                logger.info("Maximum constrained bitrate changed to \(bitrate) Kb/s")
                await bitrateDidChange()
            }
        }
    }
}
