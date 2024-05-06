//
//  AccountSheet.swift
//  Music
//
//  Created by Rasmus Krämer on 27.09.23.
//

import SwiftUI
import TipKit
import Nuke
import AFBase
import AFOffline
import AFPlayback

struct AccountSheet: View {
    @State private var username: String?
    @State private var downloads: [Track]? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                HStack(spacing: 0) {
                    ItemImage(cover: Item.Cover(type: .remote, url: URL(string: "\(JellyfinClient.shared.serverUrl!)/Users/\(JellyfinClient.shared.userId!)/Images/Primary?quality=90")!))
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
                    .padding(.leading, 15)
                }
                
                Remote()
                
                Section {
                    Button {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Label("account.settings", systemImage: "gear")
                    }
                }
                .foregroundStyle(.primary)
                
                Section("account.downloads.queue") {
                    if let downloads = downloads {
                        if downloads.isEmpty {
                            Text("account.downloads.queue.empty")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(downloads) {
                                TrackListRow(track: $0, disableMenu: true, startPlayback: {})
                            }
                        }
                    } else {
                        ProgressView()
                            .onAppear {
                                downloads = try? OfflineManager.shared.getDownloadingTracks()
                            }
                    }
                }
                
                Section {
                    Button {
                        UIApplication.shared.open(URL(string: "https://github.com/rasmuslos/AmpFin")!)
                    } label: {
                        Label("account.github", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Button {
                        UIApplication.shared.open(URL(string: "https://rfk.io/support.htm")!)
                    } label: {
                        Label("account.support", systemImage: "lifepreserver")
                    }
                }
                .foregroundStyle(.primary)
                
                Section {
                    Button(role: .destructive) {
                        JellyfinClient.shared.logout()
                    } label: {
                        Label("account.logout", systemImage: "person.crop.circle.badge.minus")
                    }
                    
                    Button(role: .destructive) {
                        SpotlightHelper.deleteSpotlightIndex()
                        ImagePipeline.shared.cache.removeAll()
                    } label: {
                        Label("account.deleteSpotlightIndex", systemImage: "square.stack.3d.up.slash")
                    }
                    
                    Button(role: .destructive) {
                        try! OfflineManager.shared.deleteAll()
                    } label: {
                        Label("account.deleteDownloads", systemImage: "slash.circle")
                    }
                }
                .foregroundStyle(.red)
                
                Section("account.server") {
                    Group {
                        Text(JellyfinClient.shared.serverUrl.absoluteString)
                        Text(JellyfinClient.shared.clientId)
                        Text(JellyfinClient.shared.token)
                            .privacySensitive()
                    }
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                }
            }
            .task {
                do {
                    (username, _, _, _) = try await JellyfinClient.shared.getUserData()
                } catch {}
            }
            #if targetEnvironment(macCatalyst)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("done")
                    }
                }
            }
            #endif
        }
    }
}

struct AccountToolbarButtonModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var accountSheetPresented = false
    
    let requiredSize: UserInterfaceSizeClass?
    
    func body(content: Content) -> some View {
        if requiredSize == nil || horizontalSizeClass == requiredSize {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            accountSheetPresented.toggle()
                        } label: {
                            Label("account", systemImage: "person.crop.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
                .sheet(isPresented: $accountSheetPresented) {
                    AccountSheet()
                }
        } else {
            content
        }
    }
}


#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            AccountSheet()
        }
}
