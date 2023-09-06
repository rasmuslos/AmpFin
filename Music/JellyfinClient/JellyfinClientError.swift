//
//  ApiError.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

enum JellyfinClientError: Error {
    case invalidServerUrl
    case invalidHttpBody
    case invalidResponse
}
