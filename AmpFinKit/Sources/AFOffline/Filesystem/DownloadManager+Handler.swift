//
//  DownloadManager+Handler.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    static var parentNotifyTask: Task<Void, Error>? = nil
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Make sure the system does not delete the file
        let tmpLocation = documents.appending(path: String(downloadTask.taskIdentifier))
        
        do {
            try? FileManager.default.removeItem(at: tmpLocation)
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            Task {
                await self.failed(taskIdentifier: downloadTask.taskIdentifier)
            }
            
            return
        }
        
        Task {
            guard let track = try? await OfflineManager.shared.offlineTrack(taskId: downloadTask.taskIdentifier) else {
                self.logger.fault("Unknown download finished")
                try? FileManager.default.removeItem(at: tmpLocation)
                
                return
            }
            
            var values = URLResourceValues()
            let mimeType = downloadTask.response?.mimeType
            setTrackFileType(track: track, mimeType: mimeType)
            var destination = url(track: track)
            
            values.isExcludedFromBackup = true
            try? destination.setResourceValues(values)
            
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: tmpLocation, to: destination)
                track.downloadId = nil
                track.container = .flac
                
                NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: track.id)
                
                Self.parentNotifyTask?.cancel()
                Self.parentNotifyTask = Task.detached {
                    try await Task.sleep(nanoseconds: UInt64(0.5) * NSEC_PER_SEC)
                    
                    for parentId in try await OfflineManager.shared.parentIds(childId: track.id) {
                        NotificationCenter.default.post(name: OfflineManager.itemDownloadStatusChanged, object: parentId)
                    }
                }
                
                self.logger.info("Download finished: \(track.id) (\(track.name))")
            } catch {
                try? FileManager.default.removeItem(at: tmpLocation)
                
                Task.detached {
                    await self.failed(taskIdentifier: downloadTask.taskIdentifier)
                }
                
                return
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            return
        }
        
        Task {
            await self.failed(taskIdentifier: task.taskIdentifier)
        }
    }
}
