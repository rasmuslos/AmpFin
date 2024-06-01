//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import AVKit
import AFFoundation
import AFNetwork
#if canImport(AFOffline)
import AFOffline
#endif

// MARK: Helper

internal extension LocalAudioEndpoint {
    var mediaInfo: Track.MediaInfo? {
        get async {
            if let itemId = nowPlaying?.id, let mediaInfo = try? await JellyfinClient.shared.mediaInfo(trackId: itemId) {
                return mediaInfo
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
        
        let url = JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "api_key", value: JellyfinClient.shared.token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,webma,webm|webma,wav,aiff,aiff|aif"),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "mp4"),
            URLQueryItem(name: "transcodingProtocol", value: "hls"),
        ])
        
        return AVPlayerItem(url: url)
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
}
