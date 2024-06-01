//
//  DownloadManager.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import OSLog

public final class DownloadManager: NSObject {
    var urlSession: URLSession!
    
    let tracks: URL
    let covers: URL
    
    let documents: URL
    
    let logger = Logger(subsystem: "io.rfk.ampfin", category: "Download")
    
    override init() {
        documents = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        tracks = documents.appending(path: "tracks")
        covers = documents.appending(path: "covers")
        
        super.init()
        
        createDirectories()
        
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    func createDirectories() {
        try! FileManager.default.createDirectory(at: covers, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: tracks, withIntermediateDirectories: true)
    }
}

public extension DownloadManager {
    static let shared = DownloadManager()
}
