//
//  DownloadManager+Handler.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Make sure the system does not delete the file
        let tmpLocation = documentsURL.appending(path: String(downloadTask.taskIdentifier))
        do {
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            print("Error while moving file", error)
        }
        
        Task.detached { [self] in
            if let track = await OfflineManager.shared.getOfflineTrackByDownloadId(downloadTask.taskIdentifier) {
                let destination = getTrackUrl(trackId: track.id)
                
                do {
                    try FileManager.default.moveItem(at: tmpLocation, to: destination)
                    track.downloadId = nil
                    
                    DispatchQueue.main.sync {
                        NotificationCenter.default.post(name: NSNotification.DownloadUpdated, object: track.id)
                    }
                    print("Download finished", track.id, track.name)
                } catch {
                    print("Error while moving track", track.id, track.name, error)
                }
            } else {
                print("Unknown download finished")
            }
        }
    }
}
