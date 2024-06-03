//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFFoundation
import AFNetwork
import SwiftData

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
    
    func setTrackFileType(trackId: String, fileType: String?) {
        let offlineItem = OfflineFile(
            trackId: trackId,
            fileType: fileType)
        let ctx = ModelContext(downloadModelContainer)
        ctx.insert(offlineItem)
    }
    
    func getTrackFileType(trackId: String) -> String? {
        var descriptor = FetchDescriptor<OfflineFile>(predicate: #Predicate { $0.trackId == trackId })
        descriptor.fetchLimit = 1
        let ctx = ModelContext(downloadModelContainer)
        if let track = try? ctx.fetch(descriptor).first {
            return track.fileType
        }
        return nil
    }
    
    public func getUrlWithType(trackId: String, fileType: String?) -> URL {
        var suffix: String
        switch fileType {
        case "audio/aac":
            suffix = ".aac"
        // Both alac and aac can be in this container
        case "audio/mp4":
            suffix = ".m4a"
        case "audio/flac":
            suffix = ".flac"
        case "audio/x-flac":
            suffix = ".flac"
        case "audio/mpeg":
            suffix = ".mp3"
        case "audio/wav":
            suffix = ".wav"
        case "audio/x-aiff":
            suffix = ".aiff"
        case "audio/webm":
            suffix = ".webma"
            // Use flac if unsure
        default:
            suffix = ".flac"
        }
        return tracks.appending(path: "\(trackId)\(suffix)")
    }
    
    @MainActor
    func failed(taskIdentifier: Int) {
        guard let track = try? OfflineManager.shared.offlineTrack(taskId: taskIdentifier) else {
            logger.fault("Could not resolve track from task identifier \(taskIdentifier)")
            return
        }
        
        logger.fault("Error while downloading track \(track.id) (\(track.name))")
        
        if let parents = try? OfflineManager.shared.parentIds(childId: track.id).filter({ $0 != track.album.id }) {
            for parent in parents {
                try? OfflineManager.shared.delete(playlistId: parent)
            }
        }
        
        try? OfflineManager.shared.delete(albumId: track.album.id)
    }
    func delete(trackId: String) {
        try? FileManager.default.removeItem(at: url(trackId: trackId))
        
        let ctx = ModelContext(downloadModelContainer)
        try? ctx.delete(model: OfflineFile.self, where: #Predicate { file in
            file.trackId == trackId
        })
    }
    
    public func url(trackId: String) -> URL {
        getUrlWithType(trackId: trackId, fileType: getTrackFileType(trackId: trackId))
    }
}

public extension DownloadManager {
    func downloaded(trackId: String) -> Bool {
        FileManager.default.fileExists(atPath: url(trackId: trackId).relativePath)
    }
}
