//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.07.24.
//

import Foundation
import SwiftUI

public extension AFVisuals {
    static func adjust(_ color: Color, saturation targetSaturation: CGFloat, brightness targetBrightness: CGFloat) -> Color {
        var hue: CGFloat = .zero
        var saturation: CGFloat = .zero
        var brightness: CGFloat = .zero
        var alpha: CGFloat = .zero
        
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: max(saturation, targetSaturation), brightness: min(brightness, targetBrightness), opacity: alpha)
    }
    
    static func determineExtreme(_ colors: [Color], lowest: Bool) -> Color? {
        guard var result = colors.first else {
            return nil
        }
        var current: CGFloat = .zero
        
        UIColor(result).getHue(nil, saturation: nil, brightness: &current, alpha: nil)
        
        for color in colors {
            var brightness: CGFloat = .zero
            UIColor(color).getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
            
            if (lowest && brightness < current) || (!lowest && brightness > current) {
                result = color
                current = brightness
            }
        }
        
        return result
    }
    static func determineSaturated(_ colors: [Color]) -> Color? {
        let colors = colors.sorted { lhs, rhs in
            var lhsSaturation: CGFloat = .zero
            var rhsSaturation: CGFloat = .zero
            
            UIColor(lhs).getHue(nil, saturation: &lhsSaturation, brightness: nil, alpha: nil)
            UIColor(rhs).getHue(nil, saturation: &rhsSaturation, brightness: nil, alpha: nil)
            
            return lhsSaturation > rhsSaturation
        }
        
        return colors.first
    }
}
