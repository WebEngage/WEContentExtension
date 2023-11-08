//
//  UIColor+DarkMode.swift
//
//
//  Created by Shubham Naidu on 01/11/23.
//

import Foundation
import UIKit

extension UIColor {
    @available(iOS 13.0, *)
    class func WEXWhiteColor() -> UIColor {
        return UIColor.systemBackground
    }

    @available(iOS 13.0, *)
    class func WEXGreyColor() -> UIColor {
        return UIColor.systemGray
    }

    @available(iOS 13.0, *)
    class func WEXLabelColor() -> UIColor {
        return UIColor.label
    }

    @available(iOS 13.0, *)
    class func WEXLightTextColor() -> UIColor {
        return UIColor.systemGray4
    }

    class func colorFromHexString(_ hexString: String, defaultColor: UIColor) -> UIColor {
        if hexString.isEmpty {
               return defaultColor
           }

           var rgbValue: UInt32 = 0
           let scanner = Scanner(string: hexString)

           if hexString.hasPrefix("#") {
               scanner.scanLocation = 1 // bypass '#' character
           } else {
               scanner.scanLocation = 0
           }

        scanner.scanHexInt32(&rgbValue)

           return UIColor(
               red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
               green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
               blue: CGFloat(rgbValue & 0xFF) / 255.0,
               alpha: 1.0
           )
    }
}
