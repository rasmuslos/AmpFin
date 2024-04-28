//
//  DebugView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 28.04.24.
//

import SwiftUI

struct DebugView: View {
    @State var notificationId: String = ""
    
    var body: some View {
        Form {
            TextField(String("id"), text: $notificationId)
            
            Button {
                NotificationCenter.default.post(name: Navigation.navigateAlbumNotification, object: notificationId)
            } label: {
                Text(verbatim: "album")
            }
            Button {
                NotificationCenter.default.post(name: Navigation.navigateArtistNotification, object: notificationId)
            } label: {
                Text(verbatim: "artist")
            }
            Button {
                NotificationCenter.default.post(name: Navigation.navigatePlaylistNotification, object: notificationId)
            } label: {
                Text(verbatim: "playlist")
            }
        }
    }
}

#Preview {
    DebugView()
}
