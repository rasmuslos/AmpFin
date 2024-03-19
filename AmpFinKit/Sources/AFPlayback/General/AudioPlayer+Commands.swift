//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 23.02.24.
//

import Foundation
import MediaPlayer

extension AudioPlayer {
    func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            playing = true
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            playing = false
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
            playing = !playing
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent {
                let positionSeconds = changePlaybackPositionCommandEvent.positionTime
                currentTime = positionSeconds
                
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            advanceToNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            backToPreviousItem()
            return .success
        }
        
#if canImport(AFOffline)
        commandCenter.likeCommand.isEnabled = false
        commandCenter.likeCommand.addTarget { event in
            if let event = event as? MPFeedbackCommandEvent {
                Task.detached { [self] in
                    await nowPlaying?.setFavorite(favorite: !event.isNegative)
                }
                
                return .success
            }
            
            return .commandFailed
        }
#endif
        
        commandCenter.changeShuffleModeCommand.isEnabled = true
        commandCenter.changeShuffleModeCommand.addTarget { event in
            if let event = event as? MPChangeShuffleModeCommandEvent {
                switch event.shuffleType {
                    case .off:
                        self.shuffled = false
                    default:
                        self.shuffled = true
                }
                
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.changeRepeatModeCommand.isEnabled = true
        commandCenter.changeRepeatModeCommand.addTarget { event in
            if let event = event as? MPChangeRepeatModeCommandEvent {
                switch event.repeatType {
                    case .off:
                        self.repeatMode = .none
                    case .one:
                        self.repeatMode = .track
                    case .all:
                        self.repeatMode = .queue
                    @unknown default:
                        Self.logger.error("Unknown repeat type")
                }
                
                return .success
            }
            
            return .commandFailed
        }
    }
    
    func updateCommandCenter(favorite: Bool) {
        MPRemoteCommandCenter.shared().changeRepeatModeCommand.currentRepeatType = repeatMode == .track ? .one : repeatMode == .queue ? .all : .off
        MPRemoteCommandCenter.shared().likeCommand.isActive = favorite
    }
}
