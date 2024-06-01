//
//  Date+Parse.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

internal extension Date {
    init?(_ from: String?) {
        guard let from = from, let date = from.components(separatedBy: "T").first else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let timestamp = formatter.date(from: date)?.timeIntervalSince1970 else {
            return nil
        }
        
        self.init(timeIntervalSince1970: timestamp)
    }
}
