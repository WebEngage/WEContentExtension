//
//  WEXCoreUtils.swift
//
//
//  Created by Shubham Naidu on 01/11/23.
//

import Foundation

struct WEXCoreUtils {
    
    static func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "gb")
        return formatter
    }
    
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
    
    static func containsHTML(_ value: String) -> Bool {
        return value.range(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", options: .regularExpression) != nil
    }
    
    static func setExtensionDefaults() {
        if let sharedDefaults = getSharedUserDefaults() {
            if sharedDefaults.value(forKey: WEConstants.WEX_CONTENT_EXTENSION_VERSION_STRING) == nil {
                sharedDefaults.setValue(WEConstants.WEX_CONTENT_EXTENSION_VERSION, forKey: WEConstants.WEX_CONTENT_EXTENSION_VERSION_STRING)
                sharedDefaults.synchronize()
            }
        }
    }
}


