//
//  String+Random.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 23.12.23.
//

import Foundation

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
