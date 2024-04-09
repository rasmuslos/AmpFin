//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBase

extension DownloadManager {
    func download(track: Track) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "universal").appending(queryItems: [
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
    
    func getTrackFileType(trackId: String) -> String? {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        let ctx = ModelContext(PersistenceManager.shared.modelContainer)
        if let track = try? ctx.fetch(descriptor).first {
            return track.fileType
        }
        return nil
    }
    
    func delete(trackId: String) {
        try? FileManager.default.removeItem(at: getUrl(trackId: trackId))
    }
    
    public func getUrl(trackId: String) -> URL {
        getUrlWithType(trackId: trackId, fileType: getTrackFileType(trackId: trackId))
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
        // the audio player refuses to play anything without an extension. but it can be wrong...
        return documentsURL.appending(path: "tracks").appending(path: "\(trackId)\(suffix)")
    }
}

extension DownloadManager {
    public func isDownloaded(trackId: String) -> Bool {
        FileManager.default.fileExists(atPath: getUrl(trackId: trackId).relativePath)
    }
}
