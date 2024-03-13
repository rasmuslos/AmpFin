//
//  Double+Duration.swift
//  iOS
//
//  Created by Rasmus Krämer on 13.03.24.
//

import Foundation

extension Double {
    func formatDuration() -> String {
        let seconds = Int(self)
        let hours = seconds / 3600
        
        if hours > 0 {
            return String(localized: "hours \(hours)")
        } else {
            return String(localized: "minutes \((seconds % 3600) / 60)")
        }
    }
}
