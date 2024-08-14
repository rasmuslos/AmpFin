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
    func didPlayToEndTime() {
        if let nowPlaying {
            history.append(nowPlaying)
            
            if avPlayerQueue.first == nowPlaying.id {
                avPlayerQueue.removeFirst()
            }
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
        
        nowPlaying = queue.first
        
        audioPlayer.advanceToNextItem()
        playing = !queueWasEmpty || repeatMode != .none
        
        avPlayerQueue.removeFirst()
        queue.removeFirst()
        
        if !playing {
            audioPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1000))
        }
    }
}

internal extension LocalAudioEndpoint {
    func advance() {
        if queue.count == 0 {
            restorePlayed(upTo: 0)
            
            if repeatMode != .queue {
                playing = false
            }
            
            return
        }
        
        didPlayToEndTime()
    }
    func rewind() {
        if currentTime > 5 || history.count < 1 {
            currentTime = 0
            return
        }
        
        let previous = history.removeLast()
        
        if let nowPlaying = nowPlaying {
            queue.insert(nowPlaying, at: 0)
        }
        
        queue.insert(previous, at: 0)
        advance()
        
        history.removeLast()
    }
    func skip(to index: Int) {
        guard queue.count > index else {
            return
        }
        
        history.append(contentsOf: queue[0..<index])
        queue.remove(atOffsets: IndexSet(0..<index))
        
        advance()
    }
    
    func queue(_ track: Track, after index: Int, updateUnalteredQueue: Bool = true) {
        if updateUnalteredQueue {
            unalteredQueue.insert(track, at: index)
        }
        
        queue.insert(track, at: index)
    }
    func queue(_ tracks: [Track], after index: Int) {
        for (i, track) in tracks.enumerated() {
            queue(track, after: index + i)
        }
    }
    
    func remove(at index: Int) -> Track? {
        if queue.count < index + 1 {
            return nil
        }
        
        let track = queue.remove(at: index)
        
        if let index = unalteredQueue.firstIndex(where: { $0.id == track.id }) {
            unalteredQueue.remove(at: index)
        }
        
        return track
    }
    func removePlayed(at index: Int) {
        history.remove(at: index)
    }
    
    func move(from index: Int, to destination: Int) {
        guard let track = remove(at: index) else {
            return
        }
            
        if index < destination {
            queue(track, after: index - 1)
        } else {
            queue(track, after: index)
        }
    }
    
    func restorePlayed(upTo index: Int) {
        let amount = history.count - index
        for track in history.suffix(amount).reversed() {
            queue(track, after: 0, updateUnalteredQueue: false)
        }
        
        history.removeLast(amount)
        
        if let nowPlaying = nowPlaying {
            queue(nowPlaying, after: queue.count)
        }
        
        advance()
        history.removeLast()
    }
}
