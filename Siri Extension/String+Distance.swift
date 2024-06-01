//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 06.01.24.
//

import Foundation

internal extension String {
    func levenshteinDistanceScore(to string: String) -> Double {
        let firstString = self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let secondString = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let empty = [Int](repeating:0, count: secondString.count)
        var last = [Int](0...secondString.count)
        
        for (i, tLett) in firstString.enumerated() {
            var cur = [i + 1] + empty
            for (j, sLett) in secondString.enumerated() {
                cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j])+1
            }
            last = cur
        }
        
        let lowestScore = max(firstString.count, secondString.count)
        
        if let validDistance = last.last {
            return  1 - (Double(validDistance) / Double(lowestScore))
        }
        
        return 0.0
    }
}
