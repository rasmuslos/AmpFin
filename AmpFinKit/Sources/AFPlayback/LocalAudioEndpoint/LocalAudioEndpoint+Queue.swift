//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import AVKit
import AFFoundation

internal extension LocalAudioEndpoint {
    func trackDidFinish() {
        if let nowPlaying = nowPlaying {
            history.append(nowPlaying)
        }
        
        let queueWasEmpty: Bool
        
        if queue.isEmpty {
            queue = history
            history = []
            
            queueWasEmpty = true
        } else {
            queueWasEmpty = false
        }
        
        guard !queue.isEmpty else {
            stopPlayback()
            return
        }
        
        setNowPlaying(track: queue.removeFirst())
        
        if !avPlayerQueue.isEmpty {
            avPlayerQueue.removeFirst()
        }
        
        if let nowPlaying {
            if avPlayerQueue.first == nowPlaying.id {
                audioPlayer.advanceToNextItem()
            }
            
            populateAVPlayerQueue()
            playing = !queueWasEmpty || repeatMode != .none
        }
        
        if !playing {
            audioPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1000))
        }
        
        setupNowPlayingMetadata()
    }
    
    func populateAVPlayerQueue() {
        guard let nowPlaying else {
            return
        }
        
        var tracks = [nowPlaying]
        var startIndex = -1
        
        tracks += queue.prefix(4)
        
        for (index, track) in tracks.enumerated() {
            guard avPlayerQueue.count > index else {
                startIndex = index
                break
            }
            
            if avPlayerQueue[index] == track.id {
                continue
            }
            
            startIndex = index
            break
        }
        
        guard startIndex > -1 else {
            return
        }
        
        logger.info("AVQueuePlayer queue outdated after index \(startIndex) / \(self.avPlayerQueue.count)")
        
        for item in audioPlayer.items()[startIndex..<audioPlayer.items().count] {
            audioPlayer.remove(item)
        }
        
        while startIndex < avPlayerQueue.count {
            avPlayerQueue.removeLast()
        }
        
        for track in tracks[startIndex..<tracks.count] {
            audioPlayer.insert(avPlayerItem(track: track), after: nil)
            avPlayerQueue.append(track.id)
        }
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
        
        if let nowPlaying = nowPlaying {
            queue.insert(nowPlaying, at: 0)
        }
        
        let previous = history.removeLast()
        setNowPlaying(track: previous)
        populateAVPlayerQueue()
        
        setupNowPlayingMetadata()
    }
    
    func skip(to: Int) {
        guard queue.count > to else {
            return
        }
        
        history.append(contentsOf: queue[0..<to])
        queue.remove(atOffsets: IndexSet(0..<to))
        
        advanceToNextTrack()
    }
    
    // MARK: Updating
    
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool = true) {
        if updateUnalteredQueue {
            unalteredQueue.insert(track, at: index)
        }
        
        queue.insert(track, at: index)
        populateAVPlayerQueue()
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
        
        let track = queue.remove(at: index)
        if let index = unalteredQueue.firstIndex(where: { $0.id == track.id }) {
            unalteredQueue.remove(at: index)
        }
        
        populateAVPlayerQueue()
        
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
        
        populateAVPlayerQueue()
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
