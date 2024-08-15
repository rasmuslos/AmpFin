//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

protocol AudioEndpoint {
    var playing: Bool { get set }
    var volume: Float { get set }
    
    var duration: Double { get }
    var currentTime: Double { get set }
    
    var history: [Track] { get }
    var nowPlaying: Track? { get }
    
    var queue: [Track] { get }
    var infiniteQueue: [Track]? { get }
    
    var buffering: Bool { get }
    
    var shuffled: Bool { get set }
    var repeatMode: RepeatMode { get set }
    
    var mediaInfo: Track.MediaInfo? { get async }
    var outputRoute: AudioPlayer.AudioRoute { get }
    
    var allowQueueLater: Bool { get }
    
    func seek(to seconds: Double) async
    
    func startPlayback(tracks: [Track], startIndex: Int, shuffle: Bool)
    func stopPlayback()
    
    func advance()
    func rewind()
    
    func removePlayed(at index: Int)
    
    func remove(at index: Int) -> Track?
    func queue(_ track: Track, after index: Int, updateUnalteredQueue: Bool)
    func queue(_ tracks: [Track], after index: Int)
    
    func move(from index: Int, to destination: Int)
    
    func skip(to index: Int)
    func restorePlayed(upTo index: Int)
}
