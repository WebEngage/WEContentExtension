//
//  WEXAnalytics.swift
//
//
//  Created by Shubham Naidu on 01/11/23.
//

import Foundation

struct WEXAnalytics {
    
    // This static method is responsible for tracking internal events.
    // It receives the event name, event value (optional), and a boolean flag indicating if it's a system event.
    /// - Parameters:
    ///   - withName: The name of the event.
    ///   - andValue: A dictionary of values associated with the event (optional).
    ///   - asSystemEvent: A flag indicating whether the event is a system event.
    static func trackInternalEvent(withName eventName: String, andValue eventValue: [String: Any]?, asSystemEvent val: Bool) {
        let eventKey = "weg_event_" + UUID().uuidString
        let defaults = WEXCoreUtils.getSharedUserDefaults()
        defaults?.set(["event_name": eventName, "event_value": eventValue as Any, "is_system": val], forKey: eventKey)
        defaults?.synchronize()
    }
    
    // This static method is a wrapper for tracking events.
    // It handles cases where the event name starts with "we_" by converting it to an internal event.
    // It also sets default values for event data if not provided.
    /// - Parameters:
    ///   - withName: The name of the event.
    ///   - andValue: A dictionary of values associated with the event (optional).
    static func trackEvent(withName eventName: String, andValue eventValue: [String: Any]?) {
        
        if eventName.hasPrefix("we_") {
            trackInternalEvent(withName: String(eventName.dropFirst(3)), andValue: eventValue, asSystemEvent: true)
        } else {
            trackInternalEvent(withName: eventName, andValue: [WEConstants.EVENT_DATA_OVERRIDES: eventValue ?? [:]], asSystemEvent: false)
        }
    }
    
    // This static method is an overloaded version of the previous method, allowing tracking events without specifying event data.
    /// - Parameter eventName: The name of the event.
    static func trackEvent(withName eventName: String) {
        trackEvent(withName: eventName, andValue: nil)
    }
}
