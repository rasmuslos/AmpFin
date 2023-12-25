//
//  AlbumView+Colors.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI

extension AlbumView {
    struct ImageColors {
        var background = Color(UIColor.secondarySystemBackground)
        var primary = Color.accentColor
        var secondary = Color.secondary
        var detail = Color.gray
        var isLight = UIColor.secondarySystemBackground.isLight()
    }
    
    func getImageColors() async -> ImageColors? {
        if let cover = album.cover, let data = try? Data(contentsOf: cover.url) {
            let image = UIImage(data: data)
            
            if let colors = image?.getColors(quality: .high) {
                return ImageColors(
                    background: Color(colors.background),
                    primary: Color(colors.primary),
                    secondary: Color(colors.secondary),
                    detail: Color(colors.detail),
                    isLight: colors.background.isLight()
                )
            }
        }
        
        return nil
    }
}
