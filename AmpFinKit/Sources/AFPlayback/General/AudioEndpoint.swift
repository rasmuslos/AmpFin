//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

protocol AudioEndpoint {
    // MARK: Computed properties
    
    var playing: Bool { get set }
    var volume: Float { get set }
    
    var duration: Double { get }
    var currentTime: Double { get set }
    
    var history: [Track] { get }
    var nowPlaying: Track? { get }
    var queue: [Track] { get }
    
    var buffering: Bool { get }
    
    var shuffled: Bool { get set }
    var repeatMode: RepeatMode { get set }
    
    var mediaInfo: Track.MediaInfo? { get async }
    var outputRoute: AudioPlayer.AudioRoute { get }
    
    // MARK: Functions
    
    func seek(seconds: Double) async
    
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool)
    func stopPlayback()
    
    func advanceToNextTrack()
    func backToPreviousItem()
    
    func removeHistoryTrack(index: Int)
    
    func removeTrack(index: Int) -> Track?
    func queueTrack(_ track: Track, index: Int, updateUnalteredQueue: Bool)
    func queueTracks(_ tracks: [Track], index: Int)
    
    func moveTrack(from: Int, to: Int)
    
    func skip(to: Int)
    func restoreHistory(index: Int)
}
