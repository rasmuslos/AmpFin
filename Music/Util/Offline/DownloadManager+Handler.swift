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
            try? FileManager.default.removeItem(at: tmpLocation)
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            logger.fault("Error while moving tmp file: \(error.localizedDescription)")
            return
        }
        
        Task.detached { @MainActor [self] in
            if let track = OfflineManager.shared.getOfflineTrackByDownloadId(downloadTask.taskIdentifier) {
                let destination = getTrackUrl(trackId: track.id)
                
                do {
                    try? FileManager.default.removeItem(at: destination)
                    try FileManager.default.moveItem(at: tmpLocation, to: destination)
                    track.downloadId = nil
                    
                    NotificationCenter.default.post(name: NSNotification.TrackDownloadStatusChanged, object: track.id)
                    NotificationCenter.default.post(name: NSNotification.AlbumDownloadStatusChanged, object: track.album.id)
                    logger.info("Download finished: \(track.id) (\(track.name))")
                } catch {
                    try? FileManager.default.removeItem(at: tmpLocation)
                    try? OfflineManager.shared.deleteOfflineAlbum(track.album)
                    
                    logger.fault("Error while moving track \(track.id) (\(track.name)): \(error.localizedDescription)")
                }
            } else {
                logger.fault("Unknown download finished")
                try? FileManager.default.removeItem(at: tmpLocation)
            }
        }
    }
    
    // Error handling
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task.detached { @MainActor [self] in
                if let track = OfflineManager.shared.getOfflineTrackByDownloadId(task.taskIdentifier) {
                    try? OfflineManager.shared.deleteOfflineAlbum(track.album)
                    logger.fault("Error while downloading track \(track.id) (\(track.name)): \(error.localizedDescription)")
                } else {
                    logger.fault("Error while downloading unknown track: \(error.localizedDescription)")
                }
            }
        }
    }
}
