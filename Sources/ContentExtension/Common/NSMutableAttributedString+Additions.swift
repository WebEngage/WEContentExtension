//
//  NSMutableAttributedString+Additions.swift
//
//
//  Created by Shubham Naidu on 03/11/23.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
    // Updates the default text color in the attributed string.
    // Available only on iOS 13 and later.
    func updateDefaultTextColor() {
        if #available(iOS 13.0, *) {
            beginEditing()
            enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: self.length), options: []) { value, range, stop in
                
                if let color = value as? UIColor,
                   let colorHex = hexString(from: color),
                   colorHex == "000000" {
                    let labelColor = UIColor.WEXLabelColor()
                    removeAttribute(.foregroundColor, range: range)
                    addAttribute(.foregroundColor, value: labelColor, range: range)
                }
            }
            endEditing()
        }
    }
    
    // Converts a UIColor to its corresponding hex string representation.
    func hexString(from color: UIColor) -> String? {
        guard let components = color.cgColor.components else {
            return nil
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255))
        )
    }
    
    // Sets the font face for the entire attributed string.
    func setFontFace(with font: UIFont) {
        beginEditing()
        enumerateAttribute(.font, in: NSRange(location: 0, length: self.length), options: []) { value, range, stop in
            
            if let oldFont = value as? UIFont,
               let newFontDescriptor = oldFont.fontDescriptor.withFamily(font.familyName).withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits){
                let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
            }
        }
        endEditing()
    }
    
    // Trims leading and trailing whitespaces and newlines from the attributed string.
    func trimWhiteSpace() {
        let legalChars = CharacterSet.whitespacesAndNewlines.inverted
        if let startRange = self.string.rangeOfCharacter(from: legalChars),
           let endRange = self.string.rangeOfCharacter(from: legalChars, options: .backwards) {
            
            let startLocation = self.string.distance(from: self.string.startIndex, to: startRange.upperBound)
            let endLocation = self.string.distance(from: self.string.startIndex, to: endRange.lowerBound)
            
            let range = NSRange(location: startLocation - 1, length: endLocation - startLocation + 2)
            self.setAttributedString(self.attributedSubstring(from: range))
        } else {
            self.setAttributedString(NSAttributedString())
        }
    }

}
