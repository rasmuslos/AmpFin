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
    
    func getTrackFileType(trackId: String) -> Int? {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.id == trackId })
        descriptor.fetchLimit = 1
        let ctx = ModelContext(PersistenceManager.shared.modelContainer)
        if let track = try? ctx.fetch(descriptor).first {
            return track.downloadId
        }
        return nil
    }
    
    func delete(trackId: String) {
        try? FileManager.default.removeItem(at: getUrl(trackId: trackId))
    }
    
    public func getUrl(trackId: String) -> URL {
        getUrlWithType(trackId: trackId, typeCode: getTrackFileType(trackId: trackId))
    }
    
    public func encodeFileType(fileType: String?) -> Int {
        var code = -1;
        switch fileType {
        case "audio/flac":
            code = -1
        case "audio/aac":
            code = -2
        // Both alac and aac can be in this container
        case "audio/mp4":
            code = -3
        case "audio/x-flac":
            code = -1
        case "audio/mpeg":
            code = -4
        case "audio/wav":
            code = -5
        case "audio/x-aiff":
            code = -6
        case "audio/webm":
            code = -7
        // Use flac if unsure
        default:
            code = -1
        }
        return code
    }
    
    public func getUrlWithType(trackId: String, typeCode: Int?) -> URL {
        var suffix: String
        switch typeCode {
        case -1:
            suffix = ".flac"
        case -2:
            suffix = ".aac"
        // Both alac and aac can be in this container
        case -3:
            suffix = ".m4a"
        case -4:
            suffix = ".mp3"
        case -5:
            suffix = ".wav"
        case -6:
            suffix = ".aiff"
        case -7:
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
