//
//  WEXCoreUtils.swift
//
//
//  Created by Shubham Naidu on 01/11/23.
//

import Foundation
import UIKit

struct WEXCoreUtils {
    
    static func getAttributedString(message: String?, colorHex: String, viewController: WEXRichPushNotificationViewController?) -> NSAttributedString? {
        guard let message = message else {
            return nil
        }

        guard let attributedString = viewController?.getHtmlParsedString(message, isTitle: false, bckColor: colorHex) else {
            return nil
        }

        let rawString = attributedString.string
        let lines = rawString.components(separatedBy: "\n")
        let finalAttributedString = NSMutableAttributedString()

        for line in lines {
            if !line.isEmpty {
                guard let alignment = viewController?.naturalTextAlignmentForText(line, forDescription: true) else {
                    continue
                }

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = alignment

                let attributes: [NSAttributedString.Key: Any] = [
                    .paragraphStyle: paragraphStyle
                ]

                let attributedLine = NSAttributedString(string: line, attributes: attributes)
                finalAttributedString.append(attributedLine)
                if line != lines.last {
                    finalAttributedString.append(NSAttributedString(string: "\n"))
                }
            }
        }

        return finalAttributedString
    }

    
    // Returns a DateFormatter configured with a specific date format, UTC time zone, and GB locale.
    static func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "gb")
        return formatter
    }
    
    // Retrieves and returns the shared UserDefaults instance based on the app group configuration.
    static func getSharedUserDefaults() -> UserDefaults? {
        var appGroup = Bundle.main.object(forInfoDictionaryKey: WEConstants.WEX_APP_GROUP) as? String

        if appGroup == nil {
            var bundle = Bundle.main
            if bundle.bundleURL.pathExtension == WEConstants.APPEX {
                bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
            }
            let bundleIdentifier = bundle.object(forInfoDictionaryKey: WEConstants.CFBUNDLEIDENTIFIER) as? String
            appGroup = "\(WEConstants.GROUP).\(bundleIdentifier ?? "").\(WEConstants.WENOTIFICATIONGROUP)"
        }

        if let defaults = UserDefaults(suiteName: appGroup) {
            return defaults
        } else {
            print("Shared User Defaults could not be initialized. Ensure Shared App Groups have been enabled on Main App & Notification Service Extension Targets.")
            fatalError("Shared User Defaults initialization failed.")
        }
    }
    
    // Checks if a given string contains HTML tags using regular expressions.
    static func containsHTML(_ value: String) -> Bool {
        return value.range(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", options: .regularExpression) != nil
    }
    
    // Sets default values in the shared UserDefaults for the app extension.
    static func setExtensionDefaults() {
        if let sharedDefaults = getSharedUserDefaults() {
                sharedDefaults.setValue(WEConstants.WEX_CONTENT_EXTENSION_VERSION, forKey: WEConstants.WEX_CONTENT_EXTENSION_VERSION_STRING)
                sharedDefaults.synchronize()
        }
    }
}


extension Character {
    var isKeycapEmoji: Bool {
        // Check if the character is a keycap emoji (e.g., 🆗 or 🆕)
        guard let scalar = unicodeScalars.first else { return false }
        let keycapRange = CharacterSet(charactersIn: "\u{0030}"..."\u{0039}") // Digits
        let flagRange = CharacterSet(charactersIn: "\u{1F1E6}"..."\u{1F1FF}") // Regional Indicator Symbols
        let keycapBaseCheck = keycapRange.contains(scalar) || flagRange.contains(scalar)
        let combiningCharacterCheck = unicodeScalars.count > 1 // Presence of combining character
        return keycapBaseCheck && combiningCharacterCheck
    }
    
    var isTraditionalEmoji: Bool {
        // Check if the character is a traditional emoji (e.g., 😊)
        let emojiRange = CharacterSet(charactersIn: "\u{1F600}"..."\u{1F64F}") // Emoticons
                        .union(CharacterSet(charactersIn: "\u{1F300}"..."\u{1F5FF}")) // Miscellaneous Symbols and Pictographs
                        .union(CharacterSet(charactersIn: "\u{1F680}"..."\u{1F6FF}")) // Transport and Map Symbols
                        .union(CharacterSet(charactersIn: "\u{2600}"..."\u{26FF}")) // Miscellaneous Symbols
                        .union(CharacterSet(charactersIn: "\u{2700}"..."\u{27BF}")) // Dingbats
                        .union(CharacterSet(charactersIn: "\u{1F900}"..."\u{1F9FF}")) // Supplemental Symbols and Pictographs
        return unicodeScalars.count == 1 && emojiRange.contains(unicodeScalars.first!)
    }
}
