//
//  DownloadManager+Handler.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Make sure the system does not delete the file
        let tmpLocation = documentsURL.appending(path: String(downloadTask.taskIdentifier))
        let mimeType = downloadTask.response?.mimeType
        
        do {
            try? FileManager.default.removeItem(at: tmpLocation)
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            logger.fault("Error while moving tmp file: \(error.localizedDescription)")
            return
        }
        
        Task.detached { @MainActor [self] in
            if let track = try? OfflineManager.shared.getOfflineTrack(taskId: downloadTask.taskIdentifier) {
                let typeCode = encodeFileType(fileType: mimeType)
                let destination = getUrlWithType(trackId: track.id, typeCode: typeCode)
                
                do {
                    try? FileManager.default.removeItem(at: destination)
                    try FileManager.default.moveItem(at: tmpLocation, to: destination)
                    track.downloadId = typeCode
                    
                    NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
                    
                    for parentId in try OfflineManager.shared.getParentIds(childId: track.id) {
                        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: parentId)
                    }
                    
                    logger.info("Download finished: \(track.id) (\(track.name))")
                } catch {
                    try? FileManager.default.removeItem(at: tmpLocation)
                    
                    logger.fault("Error while moving track \(track.id) (\(track.name)): \(error.localizedDescription)")
                }
            } else {
                logger.fault("Unknown download finished")
                try? FileManager.default.removeItem(at: tmpLocation)
            }
        }
    }
    
    // Error handling
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task.detached { @MainActor [self] in
                if let track = try? OfflineManager.shared.getOfflineTrack(taskId: task.taskIdentifier) {
                    logger.fault("Error while downloading track \(track.id) (\(track.name)): \(error.localizedDescription)")
                } else {
                    logger.fault("Error while downloading unknown track: \(error.localizedDescription)")
                }
            }
        }
    }
}
