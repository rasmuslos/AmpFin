//
//  OfflineFile.swift
//  
//
//  Created by Gnattu OC on 6/3/24.
//

import Foundation
import SwiftData
import AFFoundation

@Model
final class OfflineFile {
    let trackId: String
    let fileType: String?
    
    init(trackId: String, fileType: String?) {
        self.trackId = trackId
        self.fileType = fileType
    }
}
