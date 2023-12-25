//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFBaseKit
import AFApiKit

extension DownloadManager {
    func downloadTrack(track: Track) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
            URLQueryItem(name: "static", value: "true")
        ])))
    }
    
    func deleteTrack(trackId: String) {
        try? FileManager.default.removeItem(at: getTrackUrl(trackId: trackId))
    }
    
    public func getTrackUrl(trackId: String) -> URL {
        // the audio player refuses to play anthing without an extension. but it can be wrong...
        documentsURL.appending(path: "tracks").appending(path: "\(trackId).flac")
    }
}

extension DownloadManager {
    public func isTrackDownloaded(trackId: String) -> Bool {
        FileManager.default.fileExists(atPath: getTrackUrl(trackId: trackId).relativePath)
    }
}
