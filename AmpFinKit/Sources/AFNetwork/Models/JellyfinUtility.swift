//
//  JellyfinClient+Other.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

internal struct UserData: Codable {
    let PlayCount: Int
    let IsFavorite: Bool
    let LastPlayedDate: String?
}

internal struct JellyfinArtist: Codable {
    let Id: String
    let Name: String
}

internal struct ImageTags: Codable {
    let Primary: String?
}

internal struct MediaStream: Codable {
    let `Type`: String?
    
    let Codec: String?
    let BitRate: Int?
    let BitDepth: Int?
    let Channels: Int?
    let SampleRate: Int?
}

public enum PlayStateCommand: String {
    case play = "Unpause"
    case pause = "Pause"
    case next = "NextTrack"
    case previous = "PreviousTrack"
    case stop = "Stop"
}

public enum PlayCommand: String {
    case next = "PlayNext"
    case last = "PlayLast"
}

// MARK: Responses

internal struct PublicServerInfoResponse: Codable {
    let LocalAddress: String
    let ServerName: String
    let Version: String
    let ProductName: String
    let OperatingSystem: String
    let Id: String
    let StartupWizardCompleted: Bool
}

internal struct PublicServerInfoV10_6Response: Codable {
    let LocalAddress: String
    let ServerName: String
    let Version: String
    let ProductName: String
    let OperatingSystem: String
    let Id: String
}



internal struct AuthenticateByNameOrQuickConnectResponse: Codable {
    let AccessToken: String
    let User: User
    
    struct User: Codable {
        let Id: String
    }
}

internal struct UserDataResponse: Codable {
    let Name: String
    let ServerId: String
    let Id: String
    let HasPassword: Bool
}

internal struct LyricsResponse: Codable {
    let Lyrics: [Line]
    
    struct Line: Codable {
        let Start: Int64
        let Text: String
    }
}

internal struct QuickConnectResponse: Codable {
    let AppName: String
    let AppVersion: String
    let Authenticated: Bool
    let Code: String
    let DateAdded: String
    let DeviceId: String
    let DeviceName: String
    let Secret: String
}
