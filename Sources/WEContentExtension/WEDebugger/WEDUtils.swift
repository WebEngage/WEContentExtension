//
//  WEDUtils.swift
//  WEContentExtension
//
//  Created by Shubham Naidu on 07/12/25.
//

import Foundation

struct WEDUtils{
    
    static func isDebuggerEnabled() -> Bool {
        WEXCoreUtils.getSharedUserDefaults()?
            .string(forKey: WEDConstants.KEY_DEBUGGER_EVENT_SYNC_URL) != nil
    }
    
    /// Converts notification userInfo to [String: Any] dictionary
    /// - Parameter notification: UNMutableNotificationContent or similar with userInfo property
    /// - Returns: Dictionary with string keys and any values
    static func convertUserInfoToDictionary(_ notification: Any?) -> [String: Any] {
        guard let userInfo = (notification as? UNNotificationContent)?.userInfo else {
            return [:]
        }
        return userInfo.reduce(into: [String: Any]()) { result, element in
            if let key = element.key as? String {
                result[key] = element.value
            }
        }
    }
}
