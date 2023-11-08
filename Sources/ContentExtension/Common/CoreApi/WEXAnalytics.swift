//
//  WEXAnalytics.swift
//
//
//  Created by Shubham Naidu on 01/11/23.
//

import Foundation

struct WEXAnalytics {
    
    static func trackInternalEvent(withName eventName: String, andValue eventValue: [String: Any]?, asSystemEvent val: Bool) {
        let eventKey = "weg_event_" + UUID().uuidString
        let defaults = WEXCoreUtils.getSharedUserDefaults()
        defaults?.set(["event_name": eventName, "event_value": eventValue as Any, "is_system": val], forKey: eventKey)
        defaults?.synchronize()
    }
    
    static func trackEvent(withName eventName: String, andValue eventValue: [String: Any]?) {
        
        if eventName.hasPrefix("we_") {
            trackInternalEvent(withName: String(eventName.dropFirst(3)), andValue: eventValue, asSystemEvent: true)
        } else {
            trackInternalEvent(withName: eventName, andValue: ["event_data_overrides": eventValue ?? [:]], asSystemEvent: false)
        }
    }
    
    static func trackEvent(withName eventName: String) {
        trackEvent(withName: eventName, andValue: nil)
    }
}
