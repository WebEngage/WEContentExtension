//
//  WEDebugger.swift
//  WEServiceExtension
//
//  Created by Shubham Naidu on 25/03/25.
//

import Foundation

/// A debugger utility for making network calls.
struct WEXDebugger {
    
    private static var eventQueue: [[String: Any]] = []
    private static let maxEvents = 5
    private static let queueLock = NSLock()
    
    /// Creates an event dictionary
    static func createEvent(eventName: String,
                            eventData: [String: Any] = [:],
                            debugData: [String: Any] = [:]) -> [String: Any]? {
        
        guard let userDefaultsData = WEXCoreUtils.getSharedUserDefaults() else {
            return nil
        }
        
        var event: [String: Any] = [:]
        event["event_name"] = eventName
        event["category"] = "system"
        event["event_time"] = WEXCoreUtils.getCurrentFormattedTime()
        event["event_data"] = eventData
        event["license_code"] = userDefaultsData.string(forKey: WEConstants.WEX_LICENSE_CODE)
        event["interface_id"] = userDefaultsData.string(forKey: WEConstants.WEX_INTERFACE_ID)
        
        var systemData: [String: Any] = [:]
        systemData["app_id"] = userDefaultsData.string(forKey: WEConstants.WEX_APP_ID)
        systemData["sdk_id"] = 3
        if let sdkVersion = userDefaultsData.string(forKey: WEConstants.WEX_SDK_VERSION) as? String, let intValue = Int(sdkVersion) {
            systemData["sdk_version"] = intValue
        }
        event["system_data"] = systemData
        
        if !debugData.isEmpty {
            event["debug"] = debugData
        }
        
        return event
    }
    
    /// Queues an event and sends batch when limit is reached
    /// - Parameters:
    ///   - event: Event dictionary to queue
    ///   - completion: Completion handler called when batch is sent
    static func queueEvent(_ event: [String: Any], completion: @escaping (Int, Error?) -> Void = { _, _ in }) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        eventQueue.append(event)
        
        if eventQueue.count >= maxEvents {
            let eventsToSend = eventQueue
            eventQueue.removeAll()
            sendEvents(eventsToSend, completion: completion)
        }
    }
    
    /// Sends all queued events immediately
    /// - Parameter completion: Completion handler with status code and optional error
    static func flushEvents(completion: @escaping (Int, Error?) -> Void = { _, _ in }) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        guard !eventQueue.isEmpty else {
            completion(200, nil)
            return
        }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        sendEvents(eventsToSend, completion: completion)
    }
    
    /// Sends events to the server via POST request
    /// - Parameters:
    ///   - events: Array of event dictionaries to send
    ///   - completion: Completion handler with status code and optional error
    private static func sendEvents(_ events: [[String: Any]],
                           completion: @escaping (Int, Error?) -> Void) {
        
        guard let defaults = WEXCoreUtils.getSharedUserDefaults(), let urlString = defaults.string(forKey: WEConstants.KEY_DEBUGGER_EVENT_SYNC_URL) else {
            return
        }
                
                
        guard let url = URL(string: urlString) else {
            completion(-1, NSError(domain: "WEDNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        let headers = ["Authorization": "Bearer your_token"]
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Convert events array to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: events, options: [])
            request.httpBody = jsonData
        } catch {
            completion(-1, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(-1, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse.statusCode, nil)
            } else {
                completion(-1, NSError(domain: "WEDNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Response"]))
            }
        }
        
        task.resume()
    }
    
}


@objcMembers
public class WEGMetadataBuilder: NSObject {
    
    public static func create() -> WEGMetadataBuilder {
        return WEGMetadataBuilder()
    }
    
    private var tags: [[String: Any]] = []
    
    public func addTag(_ tag: String, metadata: [String: Any]) -> WEGMetadataBuilder {
        if let index = tags.firstIndex(where: { $0["tag"] as? String == tag }) {
            if var existingMetadata = tags[index]["metadata"] as? [String: Any] {
                existingMetadata.merge(metadata) { _, new in new }
                tags[index] = ["tag": tag, "metadata": existingMetadata]
            }
        } else {
            tags.append(["tag": tag, "metadata": metadata])
        }
        return self
    }
    
    public func build() -> [[String: Any]] {
        return tags
    }
}

@objcMembers
public class WEGLogBuilder: NSObject {
    
    private var logLevel: String = "info"
    private var logMessage: String = ""
    private var eventName: String?
    private var metadata: [[String: Any]]?
    
    public func level(_ level: String) -> WEGLogBuilder {
        logLevel = level
        return self
    }
    
    public func message(_ message: String) -> WEGLogBuilder {
        logMessage = message
        return self
    }
    
    public func eventName(_ name: String) -> WEGLogBuilder {
        eventName = name
        return self
    }
    
    public func metadata(_ meta: [[String: Any]]?) -> WEGLogBuilder {
        metadata = meta
        return self
    }
    
    public func buildEventData() -> [String: Any] {
        return [
            "log_level": logLevel,
            "log": logMessage,
            "onlydebug": 1,
            "tags": metadata ?? []
        ]
    }
}

@objcMembers
public class WEXLogProcessor: NSObject {
    public static func logReceivedNotification(loglevel: WEGLogLevel, message: Any, notification: UNNotificationContent?){
        if(!WEXCoreUtils.isDebuggerEnabled()){
            return
        }
        let userInfo = WEXCoreUtils.convertUserInfoToDictionary(notification)
        let campaign_id: String = userInfo["notification_id"] as? String ?? ""
        
        let tags = WEGMetadataBuilder.create()
            .addTag("Push Notification", metadata: [loglevel.description: userInfo])
            .addTag("Campaign_id", metadata: [loglevel.description : campaign_id])
            .addTag(WEConstants.WE_CONTENT_EXTENSION, metadata: [loglevel.description :["sdk_version": WEConstants.WEX_CONTENT_EXTENSION_VERSION,"message":message]])
            .build()
        
        let debugData = WEGLogBuilder()
            .level(loglevel.description)
            .message(campaign_id)
            .metadata(tags)
            .buildEventData()
        
        if let event = WEXDebugger.createEvent(eventName: "Content Extension", debugData: debugData){
            WEXDebugger.queueEvent(event) { statusCode, error in
                print("Debugger Data sent")
            }
        }
    }
    
    public static func logtrackEvent(loglevel: WEGLogLevel, event: Any, eventValue: [String: Any]?){
        if(!WEXCoreUtils.isDebuggerEnabled()){
            return
        }
        
        let overrides = eventValue?["system_data_overrides"] as? [String: Any]
        let campaign_id = overrides?["id"] as? String ?? ""

     
        
        let tags = WEGMetadataBuilder.create()
            .addTag("Push Notification", metadata: eventValue ?? [:])
            .addTag("Campaign_id", metadata: [loglevel.description : campaign_id])
            .addTag(WEConstants.WE_CONTENT_EXTENSION, metadata: [loglevel.description :["sdk_version": WEConstants.WEX_CONTENT_EXTENSION_VERSION,"message":event]])
            .build()
        
        let debugData = WEGLogBuilder()
            .level(loglevel.description)
            .message(campaign_id)
            .metadata(tags)
            .buildEventData()
        
        if let event = WEXDebugger.createEvent(eventName: "Content Extension Event", debugData: debugData){
            WEXDebugger.queueEvent(event) { statusCode, error in
                print("Debugger Data sent")
            }
        }
    }
}


