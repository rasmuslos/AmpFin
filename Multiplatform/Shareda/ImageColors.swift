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

class ImageColors {
    var background: Color
    var primary: Color
    var secondary: Color
    var detail: Color
    var isLight: Bool
    
    init() {
        background = .gray.opacity(0.1)
        primary = .accentColor
        secondary = .black.opacity(0.6)
        detail = .secondary
        
        isLight = !UIViewController().isDarkMode
    }
    
    init(background: Color, primary: Color, secondary: Color, detail: Color, isLight: Bool = true) {
        self.background = background
        self.primary = primary
        self.secondary = secondary
        self.detail = detail
        self.isLight = isLight
    }
}

extension ImageColors {
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

extension ImageColors {
    func updateHue(saturation: CGFloat, luminance: CGFloat) {
        background = Self.updateHue(color: background, saturation: saturation, luminance: luminance)
        primary = Self.updateHue(color: primary, saturation: saturation, luminance: luminance)
        secondary = Self.updateHue(color: secondary, saturation: saturation, luminance: luminance)
        detail = Self.updateHue(color: detail, saturation: saturation, luminance: luminance)
    }
    
    static func updateHue(color: Color, saturation: CGFloat, luminance: CGFloat) -> Color {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(hue: hue, saturation: max(saturation, saturation), brightness: min(brightness, luminance), opacity: alpha)
    }
}
