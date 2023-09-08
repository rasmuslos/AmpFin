//
//  Date+Parse.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension Date {
    static func parseDate(_ date: String?) -> Date? {
        if let date = date, let first = date.components(separatedBy: "T").first {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: first)
        }
        
        return nil
    }
}
