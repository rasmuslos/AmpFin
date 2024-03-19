//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import MediaPlayer

#if canImport(UIKit)
import UIKit
#endif

internal extension LocalAudioEndpoint {
    func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            updatePlaybackReporter(scheduled: true)
            
            _playing = audioPlayer.rate > 0
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            let duration = audioPlayer.currentItem?.duration.seconds ?? 0
            self.duration = duration.isFinite ? duration : 0
            
            let currentTime = audioPlayer.currentTime().seconds
            _currentTime = currentTime.isFinite ? currentTime : 0
        }
    }
    func setupObservers() {
        // The player is never discarded, so no removing of the observers is necessary
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [self] _ in
            if repeatMode == .track, let nowPlaying = nowPlaying {
                let item = getAVPlayerItem(nowPlaying)
                
                // i tried really good things here, but only this stupid thing works
                audioPlayer.removeAllItems()
                audioPlayer.insert(item, after: nil)
                populateQueue()
            } else {
                trackDidFinish()
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
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [self] _ in
            setNowPlaying(track: nil)
        }
        #endif
    }
}
