//
//  ImageColors.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftUI
import AFBase
import UIImageColors

struct ImageColors {
    var background = Color(UIColor.tintColor)
    var primary = Color.accentColor
    var secondary = Color.secondary
    var detail = Color.gray
    var isLight = UIColor.tintColor.isLight()
    
    static func getImageColors(cover: Item.Cover?) async -> ImageColors? {
        if let cover = cover, let data = try? Data(contentsOf: cover.url) {
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
