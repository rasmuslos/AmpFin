//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import MediaPlayer
import AVKit
import Defaults
import AFFoundation

internal extension LocalAudioEndpoint {
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        var tracks = tracks
        unalteredQueue = tracks
        
        shuffled = shuffle
        if shuffle {
            tracks.shuffle()
        }
        
        history = Array(tracks[0..<startIndex])
        queue = Array(tracks[startIndex + 1..<tracks.count])
        
        setNowPlaying(track: tracks[startIndex])
        populateAVPlayerQueue()
        
        #if !os(macOS)
        AudioPlayer.setupAudioSession()
        AudioPlayer.updateAudioSession(active: true)
        #endif
        
        playing = true
        
        setupNowPlayingMetadata()
    }
    func stopPlayback() {
        if playing {
            playing = false
        }
        
        queue = []
        unalteredQueue = []
        
        setNowPlaying(track: nil)
        history = []
        
        clearNowPlayingMetadata()
        #if !os(macOS)
        AudioPlayer.updateAudioSession(active: false)
        #endif
    }
    
    func seek(seconds: Double) async {
        await audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
        updatePlaybackReporter(scheduled: false)
    }
}

internal extension LocalAudioEndpoint {
    var playing: Bool {
        get {
            _playing
        }
        set {
            if newValue {
                audioPlayer.play()
                #if !os(macOS)
                AudioPlayer.updateAudioSession(active: true)
                #endif
            } else {
                audioPlayer.pause()
            }
            
            _playing = newValue
            
            updateNowPlayingStatus()
            updatePlaybackReporter(scheduled: false)
            
            // Make sure SwiftUI views are updated
            Task { @MainActor in
                _playing = newValue
            }
        }
    }
    
    var currentTime: Double {
        get {
            _currentTime
        }
        set {
            Task {
                await seek(seconds: newValue)
            }
        }
    }
    
    var shuffled: Bool {
        get {
            _shuffled
        }
        set {
            _shuffled = newValue
            
            if(newValue) {
                queue.shuffle()
            } else {
                queue = unalteredQueue.filter { track in
                    queue.contains { $0.id == track.id }
                }
            }
        }
    }
    var repeatMode: RepeatMode {
        get {
            _repeatMode
        }
        set {
            _repeatMode = newValue
            
            Defaults[.repeatMode] = newValue
            audioPlayer.actionAtItemEnd = newValue == .track ? .pause : .advance
        }
    }
    
    var volume: Float {
        get {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            _volume
            #else
            audioPlayer.volume
            #endif
        }
        set {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            _volume = newValue
            
            Task { @MainActor in
                MPVolumeView.setVolume(newValue)
            }
            #else
            audioPlayer.volume = newValue
            #endif
        }
    }
    
    var allowQueueLater: Bool {
        queue.count > 0
    }
}
