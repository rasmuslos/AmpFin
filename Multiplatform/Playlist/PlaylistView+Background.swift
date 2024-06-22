//
//  PlaylistView+Background.swift
//  iOS
//
//  Created by Rasmus Krämer on 01.01.24.
//

import SwiftUI
import FluidGradient
import AmpFinKit

internal extension PlaylistView {
    struct Background: View {
        let playlist: Playlist
        
        @State private var coverImage: UIImage? // playlist image on jellyfin
        
        func fetchData(from url: URL) async throws -> Data {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        
        var body: some View {
            if let coverImage = coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Rectangle()
                    .foregroundStyle(.tertiary)
                    .onAppear {
                        Task.detached {
                            do {
                                if let url = playlist.cover?.url,
                                   let uiImage = UIImage(data: try await fetchData(from: url)) {
                                    self.coverImage = uiImage
                                }
                            } catch {
                                print("Error during the retreival of the playlist image:", error)
                            }
                        }
                    }
            }
        }
    }


    }


#Preview {
    PlaylistView.Background.init(playlist: Playlist.fixture)
}
