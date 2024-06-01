//
//  Double+Duration.swift
//  iOS
//
//  Created by Rasmus Krämer on 13.03.24.
//

import Foundation

extension Double {
    var duration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        
        return formatter.string(from: TimeInterval(self))!
    }
}
