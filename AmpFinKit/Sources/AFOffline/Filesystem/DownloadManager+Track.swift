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
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: trackId).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "api_key", value: JellyfinClient.shared.token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,webma,webm|webma,wav,aiff,aif"),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "m4a"),
            URLQueryItem(name: "transcodingProtocol", value: "http"),
        ])))
    }
    
    func getTrackContainer(trackId: String) -> OfflineTrack.Container {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        let ctx = ModelContext(PersistenceManager.shared.modelContainer)
        if let track = try? ctx.fetch(descriptor).first {
            return track.container ?? .flac
        }
        return .flac
    }
    
    func setTrackFileType(track: OfflineTrack, mimeType: String?) {
        switch mimeType {
        case "audio/aac":
            track.container = .aac
            // Both alac and aac can be in this container
        case "audio/mp4":
            track.container = .m4a
        case "audio/flac":
            track.container = .flac
        case "audio/x-flac":
            track.container = .flac
        case "audio/mpeg":
            track.container = .mp3
        case "audio/wav":
            track.container = .wav
        case "audio/x-aiff":
            track.container = .aiff
        case "audio/webm":
            track.container = .webma
            // Use flac if unsure
        default:
            track.container = .flac
        }
    }
    
    @MainActor
    func failed(taskIdentifier: Int) {
        guard let track = try? OfflineManager.shared.offlineTrack(taskId: taskIdentifier) else {
            logger.fault("Could not resolve track from task identifier \(taskIdentifier)")
            return
        }
        
        logger.fault("Error while downloading track \(track.id) (\(track.name))")
        
        if let parents = try? OfflineManager.shared.parentIds(childId: track.id).filter({ $0 != track.album.albumIdentifier }) {
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
