//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFBase

extension DownloadManager {
    func download(track: Track) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "universal").appending(queryItems: [
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
    
    func delete(trackId: String) {
        try? FileManager.default.removeItem(at: getUrl(trackId: trackId))
    }
    
    public func getUrl(trackId: String) -> URL {
        // the audio player refuses to play anything without an extension. but it can be wrong...
        documentsURL.appending(path: "tracks").appending(path: "\(trackId).flac")
    }
}

extension DownloadManager {
    public func isDownloaded(trackId: String) -> Bool {
        FileManager.default.fileExists(atPath: getUrl(trackId: trackId).relativePath)
    }
}
