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
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
            URLQueryItem(name: "static", value: "true")
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
