//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFFoundation
import AFNetwork

extension DownloadManager {
    func download(trackId: String) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: trackId).appending(path: "universal").appending(queryItems: [
            URLQueryItem(name: "api_key", value: JellyfinClient.shared.token),
            URLQueryItem(name: "deviceId", value: JellyfinClient.shared.clientId),
            URLQueryItem(name: "userId", value: JellyfinClient.shared.userId),
            URLQueryItem(name: "container", value: "mp3,aac,flac,alac,webma,webm|webma,wav,aiff,aiff|aif"),
            URLQueryItem(name: "startTimeTicks", value: "0"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "transcodingContainer", value: "aac"),
            URLQueryItem(name: "transcodingProtocol", value: "http"),
        ])))
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
    
    public func url(trackId: String) -> URL {
        tracks.appending(path: "\(trackId).flac")
    }
}

public extension DownloadManager {
    func downloaded(trackId: String) -> Bool {
        FileManager.default.fileExists(atPath: url(trackId: trackId).relativePath)
    }
}
