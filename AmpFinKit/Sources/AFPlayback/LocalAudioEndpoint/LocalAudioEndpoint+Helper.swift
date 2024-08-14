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

internal extension LocalAudioEndpoint {
    func avPlayerItem(track: Track) -> AVPlayerItem {
        #if canImport(AFOffline)
        if DownloadManager.shared.downloaded(trackId: track.id) {
            return AVPlayerItem(url: DownloadManager.shared.url(trackId: track.id))
        }
        #endif
        
        var url = JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "apiKey", value: JellyfinClient.shared.token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,webma,webm|webma,wav,aiff,aiff|aif"),
            URLQueryItem(name: "playSessionId", value: JellyfinClient.sessionID(itemId: track.id, bitrate: maxBitrate)),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "mp4"),
            URLQueryItem(name: "transcodingProtocol", value: "hls"),
        ])
        
        if let bitrate = maxBitrate {
            url = url.appending(queryItems: [
                URLQueryItem(name: "maxStreamingBitrate", value: "\(UInt64(bitrate) * 1000)")
            ])
        }
        
        return AVPlayerItem(url: url)
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
        
        logger.info("AVQueuePlayer queue outdated after index \(startIndex) / \(self.avPlayerQueue.count) [\(self.audioPlayer.items().count) in queue]")
        
        let removeStartIndex = min(audioPlayer.items().count, startIndex)
        
        for item in audioPlayer.items()[removeStartIndex..<audioPlayer.items().count] {
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
    
    func determineBitrate() {
        let currentPath = networkMonitor.currentPath
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
    func setupNetworkPathMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] networkPath in
            guard let self = self else {
                return
            }
            
            switch networkPath.status {
                case .satisfied:
                    determineBitrate()
                default:
                    maxBitrate = nil
            }
        }
        
        networkMonitor.start(queue: DispatchQueue.global(qos: .userInitiated))
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
}
