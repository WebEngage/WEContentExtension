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
        var appGroup = Bundle.main.object(forInfoDictionaryKey: "WEX_APP_GROUP") as? String
        
        if appGroup == nil {
            var bundle = Bundle.main
            
            if bundle.bundleURL.pathExtension == "appex" {
                bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
            }
            
            let bundleIdentifier = bundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
            
            appGroup = "group.\(bundleIdentifier ?? "").WEGNotificationGroup"
        }
        
        if let appGroup = appGroup {
            if let defaults = UserDefaults(suiteName: appGroup) {
                return defaults
            } else {
                print("Shared User Defaults could not be initialized. Ensure Shared App Groups have been enabled on Main App & Notification Content Extension Targets.")
            }
        }
        
        return nil
    }
}

