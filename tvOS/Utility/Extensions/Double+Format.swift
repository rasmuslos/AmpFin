//
//  Double+Format.swift
//  tvOS
//
//  Created by Rasmus Krämer on 20.01.24.
//

import Foundation

extension Double {
    func hoursMinutesSeconds(padding: Bool = true) -> (String, String, String) {
        let seconds = Int64(self)
        
        if padding {
            return (
                "\(seconds / 3600)".leftPadding(toLength: 2, withPad: "0"),
                "\((seconds % 3600) / 60)".leftPadding(toLength: 2, withPad: "0"),
                "\((seconds % 3600) % 60)".leftPadding(toLength: 2, withPad: "0")
            )
        } else {
            return ("\(seconds / 3600)", "\((seconds % 3600) / 60)", "\((seconds % 3600) % 60)")
        }
    }
    
    func timeLeft() -> String {
        let (hours, minutes, seconds) = self.hoursMinutesSeconds()
        
        if hours != "00" {
            return "\(hours):\(minutes)"
        } else {
            return "\(minutes):\(seconds)"
        }
    }
}
