//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBase

protocol AudioEndpoint {
    var history: [Track] { get }
    var nowPlaying: Track? { get }
    var queue: [Track] { get }
    
    var buffering: Bool { get }
    
    var shuffled: Bool { get }
    var repeatMode: RepeatMode { get }
    
    var volume: Float { get }
    
    func setPlaying(_ playing: Bool)
    func isPlaying() -> Bool
    
    func seek(seconds: Double)
    func seek(seconds: Double) async
    
    func duration() -> Double
    func currentTime() -> Double
    
    func setVolume(_ volume: Float)
    
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool)
    func stopPlayback()
    
    func advanceToNextTrack()
    func backToPreviousItem()
    
    func shuffle(_ shuffle: Bool)
    func setRepeatMode(_ repeatMode: RepeatMode)
    
    func removeHistoryTrack(index: Int)
    
    func removeTrack(index: Int) -> Track?
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool)
    func queueTracks(_ tracks: [Track], index: Int)
    
    func moveTrack(from: Int, to: Int)
    
    func skip(to: Int)
    func restoreHistory(index: Int)
    
    func getTrackData() async -> (String, Int)?
}
