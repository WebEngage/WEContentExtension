//
//  WEConstants.swift
//
//
//  Created by Shubham Naidu on 13/11/23.
//

import Foundation

struct WEConstants{
    static let ACTION_LINK = "actionLink"
        static let APPEX = "appex"
        static let BIG_PICTURE = "BIG_PICTURE"
        static let BIG_TEXT = "BIG_TEXT"
        static let OVERLAY = "OVERLAY"
        static let BACKCOLOR = "bckColor"
        static let CAROUSEL = "CAROUSEL_V1"
        static let COLLAPSED = "collapsed"
        static let CONTENT_PADDING: CGFloat = 10.0
        static let CFBUNDLEIDENTIFIER = "CFBundleIdentifier"
        static let CUSTOM_DATA = "customData"
        static let EVENT_DATA_OVERRIDES = "event_data_overrides"
        static let EXPANDED = "expanded"
        static let EXPANDABLEDETAILS = "expandableDetails"
        static let EXPERIMENT_ID = "experiment_id"
        static let GROUP = "group"
        static let IMAGE = "image"
        static let ITEMS = "items"
        static let LANDSCAPE_ASPECT: Float = 0.5
        static let MODE = "mode"
        static let NOTIFICATION_ID = "notification_id"
        static let POTRAIT = "portrait"
        static let RATING = "RATING_V1"
        static let RATING_SCALE = "ratingScale"
        static let RICHSUBTITLE = "rst"
        static let RICHMESSAGE = "rm"
        static let RICHTITLE = "rt"
        static let SOURCE = "source"
        static let STYLE = "style"
        static let SUBMIT_CTA = "submitCTA"
        static let SYSTEM = "system"
        static let SYSTEM_DATA_OVERRIDES = "system_data_overrides"
        static let TITLE_BODY_SPACE = 5
        static let WENOTIFICATIONGROUP = "WEGNotificationGroup"
        static let WEBENGAGE = "webengage"
        static let WEX_APP_GROUP = "WEX_APP_GROUP"
        static let WEX_CONTENT_EXTENSION_VERSION = "1.1.3"
        static let WE_CONTENT_EXTENSION = "WEContentExtension"
        static let WEX_CONTENT_EXTENSION_VERSION_STRING = "WEContentExtension_version"
        static let WHITECOLOR = "#FFFFFF"
        static let KEY_DEBUGGER_EVENT_SYNC_URL = "debugger_event_sync_url"
        static let WEX_LICENSE_CODE = "license_code"
        static let WEX_INTERFACE_ID = "interface_id"
        static let WEX_SDK_VERSION = "sdk_version"
        static let WEX_APP_ID = "app_id"
}

@objc public enum WEGLogLevel: Int {
    case debug, info, warning, error, critical
    
    var description: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        case .critical: return "critical"
        }
    }
}
