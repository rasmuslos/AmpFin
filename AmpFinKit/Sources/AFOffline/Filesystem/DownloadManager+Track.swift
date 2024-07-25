//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFFoundation
import AFNetwork

extension DownloadManager {
    func download(trackId: String) -> URLSessionDownloadTask {
        var url = JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: trackId).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "apiKey", value: JellyfinClient.shared.token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,webma,webm|webma,wav,aiff,aif"),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "m4a"),
            URLQueryItem(name: "transcodingProtocol", value: "http"),
        ])
        
        let bitrate = UserDefaults.standard.integer(forKey: "bitrate_downloads")
        if bitrate > 0 {
            url = url.appending(queryItems: [
                URLQueryItem(name: "maxStreamingBitrate", value: "\(UInt64(bitrate) * 1000)"),
                URLQueryItem(name: "PlaySessionId", value: JellyfinClient.sessionID(itemId: trackId, bitrate: bitrate)),
            ])
        }
        
        return urlSession.downloadTask(with: URLRequest(url: url))
    }
    
    func getTrackContainer(trackId: String) -> OfflineTrack.Container {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        
        guard let container = try? context.fetch(descriptor).first?.container else {
            return .flac
        }
        
        return container
    }
    
    func setTrackFileType(track: OfflineTrack, mimeType: String?) {
        switch mimeType {
            case "audio/aac":
                track.container = .aac
            case "audio/mp4":
                // Both alac and aac can be in this container
                track.container = .m4a
            case "audio/mpeg":
                track.container = .mp3
            case "audio/wav":
                track.container = .wav
            case "audio/x-aiff":
                track.container = .aiff
            case "audio/webm":
                track.container = .webma
            default:
                // Use flac if unsure
                track.container = .flac
        }
    }
    
    func failed(taskIdentifier: Int) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        guard let track = try? OfflineManager.shared.offlineTrack(taskId: taskIdentifier, context: context) else {
            logger.fault("Could not resolve track from task identifier \(taskIdentifier)")
            return
        }
        
        logger.fault("Error while downloading track \(track.id) (\(track.name))")
        
        if let parents = try? OfflineManager.shared.parentIds(childId: track.id, context: context).filter({ $0 != track.album.albumIdentifier }) {
            for parent in parents {
                try? OfflineManager.shared.delete(playlistId: parent)
            }
        }
        
        try? OfflineManager.shared.delete(albumId: track.album.albumIdentifier)
    }
    func delete(trackId: String) {
        try? FileManager.default.removeItem(at: url(trackId: trackId))
    }
    
    func url(track: OfflineTrack) -> URL {
        let trackId = track.id
        let container = track.container ?? .flac
        return tracks.appending(path: "\(trackId).\(container)")
    }
    
    public func url(trackId: String) -> URL {
        let container = getTrackContainer(trackId: trackId)
        return tracks.appending(path: "\(trackId).\(container)")
    }
}

public extension DownloadManager {
    func downloaded(trackId: String) -> Bool {
        FileManager.default.fileExists(atPath: url(trackId: trackId).relativePath)
    }
}
