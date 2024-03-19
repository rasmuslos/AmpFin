//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import AFBase
import AVKit
import MediaPlayer

internal extension LocalAudioEndpoint {
    func _setPlaying(_ playing: Bool) {
        if playing {
            audioPlayer.play()
            AudioPlayer.updateAudioSession(active: true)
        } else {
            audioPlayer.pause()
        }
        
        _playing = playing
        
        updateNowPlayingStatus()
        updatePlaybackReporter(scheduled: false)
    }
    
    func _seek(seconds: Double) {
        audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000)) { _ in
            self.updatePlaybackReporter(scheduled: false)
        }
    }
    
    func _setVolume(_ volume: Float) {
        #if os(iOS)
        MPVolumeView.setVolume(volume)
        #endif
    }
}

internal extension LocalAudioEndpoint {
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        var tracks = tracks
        unalteredQueue = tracks
        
        repeatMode = .none
        
        shuffled = shuffle
        if shuffle {
            tracks.shuffle()
        }
        
        history = Array(tracks[0..<startIndex])
        queue = Array(tracks[startIndex + 1..<tracks.count])
        
        setNowPlaying(track: tracks[startIndex])
        
        audioPlayer.insert(getAVPlayerItem(nowPlaying!), after: nil)
        populateQueue()
        
        AudioPlayer.setupAudioSession()
        AudioPlayer.updateAudioSession(active: true)
        
        playing = true
        
        setupNowPlayingMetadata()
    }
    func stopPlayback() {
        if playing {
            playing = false
        }
        
        audioPlayer.removeAllItems()
        
        queue = []
        unalteredQueue = []
        
        setNowPlaying(track: nil)
        history = []
        
        clearNowPlayingMetadata()
        AudioPlayer.updateAudioSession(active: false)
    }
    
    func seek(seconds: Double) async {
        await audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
        updatePlaybackReporter(scheduled: false)
    }
}
