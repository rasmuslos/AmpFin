//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import AFBase

internal extension LocalAudioEndpoint {
    func populateQueue() {
        for track in queue {
            audioPlayer.insert(getAVPlayerItem(track), after: nil)
        }
    }
    
    func trackDidFinish() {
        if let nowPlaying = nowPlaying {
            history.append(nowPlaying)
        }
        
        if queue.isEmpty {
            audioPlayer.removeAllItems()
            
            queue = history
            history = []
            
            populateQueue()
            
            setNowPlaying(track: queue.removeFirst())
            playing = repeatMode != .none
        } else {
            setNowPlaying(track: queue.removeFirst())
        }
        
        setupNowPlayingMetadata()
    }
    
    // MARK: Modify
    
    func _shuffle(_ shuffle: Bool) {
        _shuffled = shuffle
        
        if(shuffle) {
            queue.shuffle()
        } else {
            queue = unalteredQueue.filter { track in
                queue.contains { $0.id == track.id }
            }
        }
        
        audioPlayer.items().enumerated().forEach { index, item in
            if index != 0 {
                audioPlayer.remove(item)
            }
        }
        
        populateQueue()
    }
    
    func _setRepeatMode(_ repeatMode: RepeatMode) {
        _repeatMode = repeatMode
    }
}

internal extension LocalAudioEndpoint {
    // MARK: Skipping
    
    func advanceToNextTrack() {
        if queue.count == 0 {
            restoreHistory(index: 0)
            if repeatMode != .queue {
                playing = false
            }
            
            return
        }
        
        audioPlayer.advanceToNextItem()
        
        trackDidFinish()
    }
    
    func backToPreviousItem() {
        if currentTime > 5 {
            currentTime = 0
            return
        }
        if history.count < 1 {
            return
        }
        
        let previous = history.removeLast()
        let playerItem = getAVPlayerItem(previous)
        audioPlayer.insert(playerItem, after: audioPlayer.currentItem)
        
        if let nowPlaying = nowPlaying {
            queue.insert(nowPlaying, at: 0)
            audioPlayer.insert(getAVPlayerItem(nowPlaying), after: playerItem)
        }
        
        audioPlayer.advanceToNextItem()
        setNowPlaying(track: previous)
        setupNowPlayingMetadata()
    }
    
    func skip(to: Int) {
        if queue.count < to + 1 {
            return
        }
        
        let id = queue[to].id
        while(nowPlaying?.id != id) {
            advanceToNextTrack()
        }
    }
    
    // MARK: Updating
    
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool = true) {
        if updateUnalteredQueue {
            unalteredQueue.insert(track, at: index)
        }
        
        queue.insert(track, at: index)
        
        if audioPlayer.items().count > 0 {
            audioPlayer.insert(getAVPlayerItem(track), after: audioPlayer.items()[index])
        } else {
            audioPlayer.insert(getAVPlayerItem(track), after: nil)
        }
    }
    func queueTracks(_ tracks: [Track], index: Int) {
        for (i, track) in tracks.enumerated() {
            queueTrack(track, index: index + i)
        }
    }
    
    func removeTrack(index: Int) -> Track? {
        if queue.count < index + 1 {
            return nil
        }
        
        audioPlayer.remove(audioPlayer.items()[index + 1])
        let track = queue.remove(at: index)
        if let index = unalteredQueue.firstIndex(where: { $0.id == track.id }) {
            unalteredQueue.remove(at: index)
        }
        
        return track
    }
    func removeHistoryTrack(index: Int) {
        history.remove(at: index)
    }
    
    func moveTrack(from: Int, to: Int) {
        if let track = removeTrack(index: from) {
            if let index = unalteredQueue.firstIndex(where: { $0.id == track.id }) {
                unalteredQueue.remove(at: index)
            }
            
            if from < to {
                queueTrack(track, index: to - 1)
            } else {
                queueTrack(track, index: to)
            }
        }
    }
    
    func restoreHistory(index: Int) {
        let amount = history.count - index
        for track in history.suffix(amount).reversed() {
            queueTrack(track, index: 0, updateUnalteredQueue: false)
        }
        
        history.removeLast(amount)
        
        if let nowPlaying = nowPlaying {
            queueTrack(nowPlaying, index: queue.count)
        }
        
        advanceToNextTrack()
        history.removeLast()
    }
}
