//
//  String+Adding.swift
//  tvOS
//
//  Created by Rasmus Krämer on 20.01.24.
//

import Foundation

extension String {
    func leftPadding(toLength: Int, withPad: String) -> String {
        String(String(reversed()).padding(toLength: toLength, withPad: withPad, startingAt: 0).reversed())
    }
}
