//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 19.03.24.
//

import Foundation
import AVKit
import AFBase

#if canImport(AFOffline)
import AFOffline
#endif

// MARK: Helper

internal extension LocalAudioEndpoint {
    func getTrackData() async -> Track.TrackData? {
        if let itemId = nowPlaying?.id, let trackData = try? await JellyfinClient.shared.getTrackData(id: itemId) {
            return trackData
        }
        
        let track = try? await audioPlayer.currentItem?.asset.load(.tracks).first
        
        var format = await track?.getMediaFormat()
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
    
    func getAVPlayerItem(_ track: Track) -> AVPlayerItem {
        #if canImport(AFOffline)
        if DownloadManager.shared.isDownloaded(trackId: track.id) {
            return AVPlayerItem(url: DownloadManager.shared.getUrl(trackId: track.id))
        }
        #endif
        
        #if os(watchOS)
        return AVPlayerItem(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
            URLQueryItem(name: "profile", value: "28"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "audioBitRate", value: "128000"),
            URLQueryItem(name: "audioSampleRate", value: "44100"),
        ]))
        #else
        let url = JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "api_key", value: JellyfinClient.shared.token!),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,webma,webm|webma,wav,aiff,aiff|aif"),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "mp4"),
            URLQueryItem(name: "transcodingProtocol", value: "hls"),
        ])
        
        return AVPlayerItem(url: url)
        #endif
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
        }
        
        if let track = track {
            playbackReporter = PlaybackReporter(trackId: track.id, queue: queue)
        } else {
            playbackReporter = nil
        }
    }
}
