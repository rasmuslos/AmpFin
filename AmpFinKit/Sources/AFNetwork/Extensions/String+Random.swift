//
//  String+Random.swift
//  MusicKit
//
//  Created by Rasmus Krämer on 23.12.23.
//

import Foundation

internal extension String {
    init(length: Int) {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        self.init((0..<length).map{ _ in letters.randomElement()! })
    }
}
