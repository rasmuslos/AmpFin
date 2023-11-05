//
//  AccountSheet.swift
//  Music
//
//  Created by Rasmus Krämer on 27.09.23.
//

import SwiftUI

struct AccountSheet: View {
    @State var username: String?
    
    var body: some View {
        List {
            HStack {
                ItemImage(cover: Item.Cover(type: .jellyfin, url: URL(string: "\(JellyfinClient.shared.serverUrl!)/Users/\(JellyfinClient.shared.userId!)/Images/Primary?quality=90")!))
                    .frame(width: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                
                VStack(alignment: .leading) {
                    if let username = username {
                        Text(username)
                            .font(.headline)
                            .padding(.bottom, 1)
                    } else {
                        ProgressView()
                            .scaleEffect(0.5)
                            .padding(.bottom, 1)
                    }
                    
                    Text(JellyfinClient.shared.userId)
                        .font(.caption)
                }
                .padding(.trailing, 5)
            }
            
            Section {
                Button(role: .destructive) {
                    JellyfinClient.shared.logout()
                } label: {
                    Text("account.logout")
                }
                Button(role: .destructive) {
                    Task {
                        try await OfflineManager.shared.deleteAllDownloads()
                    }
                } label: {
                    Text("account.deleteDownloads")
                }
            }
            
            Section {
                Group {
                    Text(JellyfinClient.shared.serverUrl.absoluteString)
                    Text(JellyfinClient.shared.token)
                        .privacySensitive()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            } header: {
                Text("account.server")
            }
            
            // quite ironic that this code is bad
            Section {
                HStack {
                    Spacer()
                    Text("developedBy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .task {
            do {
                (username, _, _, _) = try await JellyfinClient.shared.getUserData()
            } catch {}
        }
    }
}

#Preview {
    Text(":)")
        .sheet(isPresented: .constant(true)) {
            AccountSheet()
        }
}
