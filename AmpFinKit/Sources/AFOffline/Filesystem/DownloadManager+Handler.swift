//
//  DownloadManager+Handler.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    static var parentNotifyTask: Task<Void, Error>? = nil
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Make sure the system does not delete the file
        let tmpLocation = documents.appending(path: String(downloadTask.taskIdentifier))
        
        do {
            try? FileManager.default.removeItem(at: tmpLocation)
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            failed(taskIdentifier: downloadTask.taskIdentifier)
            return
        }
        
        Task {
            do {
                let context = ModelContext(PersistenceManager.shared.modelContainer)
                guard let track = try? OfflineManager.shared.offlineTrack(taskId: downloadTask.taskIdentifier, context: context) else {
                    throw OfflineManager.OfflineError.notFound
                }
                
                let mimeType = downloadTask.response?.mimeType
                setTrackFileType(track: track, mimeType: mimeType)
                
                var destination = url(track: track)
                
                track.downloadId = nil
                let trackId = track.id
                
                try context.save()
                
                // At this point there are no references to the SwiftData object, so we can call `Task.yield()` safely
                
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: tmpLocation, to: destination)
                
                NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: trackId)
                
                Self.parentNotifyTask?.cancel()
                Self.parentNotifyTask = Task.detached {
                    try await Task.sleep(nanoseconds: UInt64(0.5) * NSEC_PER_SEC)
                    
                    let context = ModelContext(PersistenceManager.shared.modelContainer)
                    let parentIDs = try OfflineManager.shared.parentIds(childId: trackId, context: context)
                    
                    for parentID in parentIDs {
                        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: parentID)
                    }
                }
                
                self.logger.info("Download finished: \(trackId)")
            } catch {
                try? FileManager.default.removeItem(at: tmpLocation)
                failed(taskIdentifier: downloadTask.taskIdentifier)
                
                return
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            return
        }
        
        failed(taskIdentifier: task.taskIdentifier)
    }
}
