//
//  PlayerModel.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

@Observable
class PlayerModel {
    private(set) var nowPlayingItem: SongItem?
    private(set) var audioPlayer: AudioPlayer?
    
    var expanded = false
}
