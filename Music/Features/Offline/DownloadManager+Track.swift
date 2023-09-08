//
//  DownloadManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension DownloadManager {
    func downloadTrack(track: Track) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: JellyfinClient.shared.serverUrl.appending(path: "Audio").appending(path: track.id).appending(path: "stream").appending(queryItems: [
            URLQueryItem(name: "static", value: "true")
        ])))
    }
    
    func deleteTrack(trackId: String) {
        try? FileManager.default.removeItem(at: getTrackUrl(trackId: trackId))
    }
    
    func getTrackUrl(trackId: String) -> URL {
        // the audio player refuses to stuff without an extension. but it can be wrong...
        documentsURL.appending(path: "tracks").appending(path: "\(trackId).mp3")
    }
}
