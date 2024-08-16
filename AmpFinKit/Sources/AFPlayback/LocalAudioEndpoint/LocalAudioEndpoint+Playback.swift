//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import Defaults

import AVKit
import MediaPlayer

import AFFoundation
import AFNetwork
#if canImport(AFOffline)
import AFOffline
#endif

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
        nowPlaying = tracks[startIndex]
        queue = Array(tracks[startIndex + 1..<tracks.count])
        
        #if !os(macOS)
        AudioPlayer.setupAudioSession()
        AudioPlayer.updateAudioSession(active: true)
        #endif
        
        playing = true
    }
    func stopPlayback() {
        playing = false
        
        history = []
        nowPlaying = nil
        
        avPlayerQueue = []
        
        queue = []
        infiniteQueue = []
        unalteredQueue = []
        
        clearNowPlayingWidget()
        
        #if !os(macOS)
        AudioPlayer.updateAudioSession(active: false)
        #endif
    }
    
    func seek(to seconds: Double) async {
        await audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
        
        updatePlaybackReporter(scheduled: false)
        NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
    }
    
    var mediaInfo: Track.MediaInfo? {
        get async {
            if let itemId = nowPlaying?.id {
                let serverBitrateLikelyToBeFalse = DownloadManager.shared.downloaded(trackId: itemId) && Defaults[.maxDownloadBitrate] > 0
                
                if !serverBitrateLikelyToBeFalse, var mediaInfo = try? await JellyfinClient.shared.mediaInfo(trackId: itemId) {
                    guard let maxBitrate, let bitrate = mediaInfo.bitrate else {
                        return mediaInfo
                    }
                    
                    let maxBitrateBits = maxBitrate * 1000
                    
                    if (bitrate > maxBitrateBits) {
                        mediaInfo.bitrate = maxBitrateBits
                        mediaInfo.codec = "AAC"
                        mediaInfo.lossless = false
                    }
                    
                    return mediaInfo
                }
            }
            
            let track = try? await audioPlayer.currentItem?.asset.load(.tracks).first
            
            var format = await track?.mediaFormat()
            let bitrate = try? await track?.load(.estimatedDataRate)
            
            if format != nil {
                while format!.starts(with: ".") {
                    format!.removeFirst()
                }
            }
            
            var bitrateInt: Int?
            if let bitrate, bitrate > 0 {
                bitrateInt = Int(bitrate)
            }
            
            return .init(codec: format, lossless: false, bitrate: bitrateInt, bitDepth: nil, sampleRate: nil)
        }
    }
}
