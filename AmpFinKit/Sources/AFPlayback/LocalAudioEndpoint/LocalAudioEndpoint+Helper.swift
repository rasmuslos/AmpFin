//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import Network
import AVKit
import Defaults

import AFFoundation
import AFNetwork
#if canImport(AFOffline)
import AFOffline
#endif

// MARK: Helper

internal extension LocalAudioEndpoint {
    var mediaInfo: Track.MediaInfo? {
        get async {
            if let itemId = nowPlaying?.id {
                let serverBitrateLikelyToBeFalse = DownloadManager.shared.downloaded(trackId: itemId) && Defaults[.maxDownloadBitrate] > 0
                
                if !serverBitrateLikelyToBeFalse, var mediaInfo = try? await JellyfinClient.shared.mediaInfo(trackId: itemId) {
                    guard let maxBitrate, let bitrate = mediaInfo.bitrate else {
                        return mediaInfo
                    }
                    
                    let maxBitrateBits = maxBitrate * 1000
                    
                    mediaInfo.bitrate = min(bitrate, maxBitrateBits)
                    return mediaInfo
                }
            }
            
            let track = try? await audioPlayer.currentItem?.asset.load(.tracks).first
            
            var format = await track?.mediaFormat()
            var bitrate = try? await track?.load(.estimatedDataRate)
            
            if format != nil {
                while format!.starts(with: ".") {
                    format!.removeFirst()
                }
            }
            if bitrate != nil {
                bitrate = (bitrate! / 1000).rounded()
            }
            
            return .init(codec: format, lossless: false, bitrate: bitrate != nil && bitrate! > 0 ? Int(bitrate!) : nil, bitDepth: nil, sampleRate: nil)
        }
    }
    
    func avPlayerItem(track: Track) -> AVPlayerItem {
        #if canImport(AFOffline)
        if DownloadManager.shared.downloaded(trackId: track.id) {
            return AVPlayerItem(url: DownloadManager.shared.url(trackId: track.id))
        }
        #endif
        
        var url = JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "api_key", value: JellyfinClient.shared.token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,webma,webm|webma,wav,aiff,aiff|aif"),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "mp4"),
            URLQueryItem(name: "transcodingProtocol", value: "hls"),
        ])
        
        determineBitrate()
        
        if let bitrate = maxBitrate {
            url = url.appending(queryItems: [
                URLQueryItem(name: "maxStreamingBitrate", value: "\(UInt64(bitrate) * 1000)")
            ])
        }
        
        print(url)
        
        return AVPlayerItem(url: url)
    }
    
    func determineBitrate() {
        let currentPath = NWPathMonitor().currentPath
        let bitrate: Int
        
        if currentPath.isExpensive || currentPath.isConstrained {
            bitrate = Defaults[.maxConstrainedBitrate]
        } else {
            bitrate = Defaults[.maxStreamingBitrate]
        }
        
        if bitrate <= 0 {
            maxBitrate = nil
        } else {
            maxBitrate = bitrate
        }
    }
    func bitrateDidChange() async {
        let currentTime = currentTime
        
        avPlayerQueue = []
        populateAVPlayerQueue()
        
        await seek(seconds: currentTime)
        await MainActor.run {
            NotificationCenter.default.post(name: AudioPlayer.bitrateChangedNotification, object: nil)
        }
    }
    
    func updatePlaybackReporter(scheduled: Bool) {
        playbackReporter?.update(
            positionSeconds: currentTime,
            paused: !playing,
            repeatMode: repeatMode,
            shuffled: shuffled,
            volume: volume,
            scheduled: scheduled)
    }
    
    func setNowPlaying(track: Track?) {
        nowPlaying = track
        
        if let track = track {
            AudioPlayer.current.updateCommandCenter(favorite: track.favorite)
            playbackReporter = PlaybackReporter(trackId: track.id, queue: queue)
        } else {
            playbackReporter = nil
        }
    }
    
    static func audioRoute() -> AudioPlayer.AudioRoute {
        let output = AVAudioSession.sharedInstance().currentRoute.outputs.first
        return .init(port: output?.portType ?? .builtInSpeaker, name: output?.portName ?? "-/-")
    }
}
