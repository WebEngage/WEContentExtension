import UserNotifications
import UserNotificationsUI
import UIKit

let WEX_CONTENT_EXTENSION_VERSION = "1.0.2"

@available(iOS 10.0, *)
open class WEXRichPushNotificationViewController: UIViewController,UNNotificationContentExtension {

    var label: UILabel?
    var currentLayout: WEXRichPushLayout?
    var notification: UNNotification?
    var richPushDefaults: UserDefaults?
    var isRendering: Bool = false
    var isDarkMode: Bool = false

    open override func loadView() {
        self.view = UIView()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if let label = self.label {
            label.removeFromSuperview()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateActivity(object: true, forKey: "collapsed")
        DispatchQueue.main.async {
            self.label?.removeFromSuperview()
            self.currentLayout = nil
            self.notification = nil
        }
    }

    open override var canBecomeFirstResponder: Bool {
        if let currentLayout = self.currentLayout{
            return true
        }
        return false
    }

    open override var inputAccessoryView: UIView? {
        if let currentLayout = self.currentLayout, currentLayout.responds(to: #selector(getter: self.inputAccessoryView)) {
            if let accessoryView = currentLayout.perform(#selector(getter: self.inputAccessoryView))?.takeUnretainedValue() as? UIView {
                return accessoryView
            }
        }
        return super.inputAccessoryView
    }


    open override var inputView: UIView? {
        if let currentLayout = self.currentLayout, currentLayout.responds(to: #selector(getter: self.inputView)) {
            if let accessoryView = currentLayout.perform(#selector(getter: self.inputView))?.takeUnretainedValue() as? UIView {
                return accessoryView
            }
        }
        return super.inputView
    }

    public func didReceive(_ notification: UNNotification) {
        if notification.request.content.userInfo["source"] as? String == "webengage" {
            self.notification = notification
            isRendering = true
            updateDarkModeStatus()
            setExtensionDefaults()
            var appGroup = Bundle.main.object(forInfoDictionaryKey: "WEX_APP_GROUP") as? String

            if appGroup == nil {
                var bundle = Bundle.main
                if bundle.bundleURL.pathExtension == "appex" {
                    bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
                }
                let bundleIdentifier = bundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
                appGroup = "group.\(bundleIdentifier ?? "").WEGNotificationGroup"
            }

            richPushDefaults = UserDefaults(suiteName: appGroup)

            updateActivity(object: false, forKey: "collapsed")
            updateActivity(object: true, forKey: "expanded")

            if let expandableDetails = notification.request.content.userInfo["expandableDetails"] as? [String: Any], let style = expandableDetails["style"] as? String {
                currentLayout = layoutForStyle(style)
                currentLayout?.didReceiveNotification(notification)
            }
        }
    }

    func setExtensionDefaults() {
        let sharedDefaults = getSharedUserDefaults()
        if sharedDefaults.value(forKey: "WEG_Content_Extension_Version") == nil {
            sharedDefaults.setValue(WEX_CONTENT_EXTENSION_VERSION, forKey: "WEG_Content_Extension_Version")
            sharedDefaults.synchronize()
        }
    }

    func getSharedUserDefaults() -> UserDefaults {
        var appGroup = Bundle.main.object(forInfoDictionaryKey: "WEX_APP_GROUP") as? String

        if appGroup == nil {
            var bundle = Bundle.main
            if bundle.bundleURL.pathExtension == "appex" {
                bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
            }
            let bundleIdentifier = bundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
            appGroup = "group.\(bundleIdentifier ?? "").WEGNotificationGroup"
        }

        if let defaults = UserDefaults(suiteName: appGroup) {
            return defaults
        } else {
            print("Shared User Defaults could not be initialized. Ensure Shared App Groups have been enabled on Main App & Notification Service Extension Targets.")
            fatalError("Shared User Defaults initialization failed.")
        }
    }

    func layoutForStyle(_ style: String) -> WEXRichPushLayout? {
        switch style {
        case "CAROUSEL_V1":
            return WEXCarouselPushNotificationViewController(notificationViewController: self)
        case "RATING_V1":
            return WEXRatingPushNotificationViewController(notificationViewController: self)
        case "BIG_PICTURE":
            return WEXBannerPushNotificationViewController(notificationViewController: self)
        case "BIG_TEXT":
            return WEXTextPushNotificationViewController(notificationViewController: self)
        default:
            return nil
        }
    }

    public func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo["source"] as? String, source == "webengage" {
            self.currentLayout?.didReceiveNotificationResponse(response, completionHandler: completion)
        }
    }


    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDarkModeStatus()
    }

    func getActivityDictionaryForCurrentNotification() -> NSMutableDictionary {
        guard let expId = notification?.request.content.userInfo["experiment_id"] as? String,
              let notifId = notification?.request.content.userInfo["notification_id"] as? String else {
            return NSMutableDictionary()
        }

        let finalNotifId = "\(expId)|\(notifId)"
        let expandableDetails = notification?.request.content.userInfo["expandableDetails"]
        let customData = notification?.request.content.userInfo["customData"] as? [Any]

        var dictionary = (richPushDefaults?.dictionary(forKey: finalNotifId) as? NSMutableDictionary) ?? NSMutableDictionary()
        if dictionary.count == 0 {
            dictionary["experiment_id"] = expId
            dictionary["notification_id"] = notifId
            dictionary["expandableDetails"] = expandableDetails
            if let customData = customData {
                dictionary["customData"] = customData
            }
        }
        return dictionary
    }

    func updateActivity(object: Any, forKey key: String) {
        if let activityDictionary = getActivityDictionaryForCurrentNotification() as? [String: Any] {
            var updatedActivityDictionary = activityDictionary
            updatedActivityDictionary[key] = object
            setActivityForCurrentNotification(activity: updatedActivityDictionary)
        }
    }

    func setActivityForCurrentNotification(activity: [String: Any]) {
        guard let expId = notification?.request.content.userInfo["experiment_id"] as? String,
              let notifId = notification?.request.content.userInfo["notification_id"] as? String else {
            return
        }

        let finalNotifId = "\(expId)|\(notifId)"
        richPushDefaults?.set(activity, forKey: finalNotifId)
        richPushDefaults?.synchronize()
    }

    func addSystemEvent(name eventName: String, systemData: [String: Any], applicationData: [String: Any]) {
        addEvent(name: eventName, systemData: systemData, applicationData: applicationData, category: "system")
    }

    func addEvent(name eventName: String, systemData: [String: Any], applicationData: [String: Any], category: String) {
        let customData = notification?.request.content.userInfo["customData"] as? [Any]
        var customDataDictionary = [String: Any]()

        if let customData = customData as? [[String: Any]] {
            for customDataItem in customData {
                if let key = customDataItem["key"] as? String,
                   let value = customDataItem["value"] {
                    customDataDictionary[key] = value
                }
            }
        }

        if category == "system" {
            WEXAnalytics.trackEvent(withName: "we_\(eventName)", andValue: [
                "system_data_overrides": systemData,
                "event_data_overrides": customDataDictionary
            ])
        } else {
            WEXAnalytics.trackEvent(withName: eventName, andValue: customDataDictionary)
        }
    }

    func setCTAWithId(_ ctaId: String, andLink actionLink: String) {
        let cta = ["id": ctaId, "actionLink": actionLink]
        updateActivity(object: cta, forKey: "cta")
    }

    func naturalTextAligmentForText(_ text: String?) -> NSTextAlignment {
        guard let text = text, !text.isEmpty else {
            return .left
        }

        let tagschemes = [NSLinguisticTagScheme.language]
        let tagger = NSLinguisticTagger(tagSchemes: tagschemes, options: 0)
        tagger.string = text
        if let language = tagger.tag(at: 0, scheme: .language, tokenRange: nil, sentenceRange: nil) {
            if language.rawValue == "he" || language.rawValue == "ar" {
                return .right
            } else {
                return .left
            }
        }
        return .center
    }

    func getHtmlParsedString(_ textString: String, isTitle: Bool, bckColor: String) -> NSAttributedString? {
        let containsHTML = self.containsHTML(textString)
        var inputString = textString

        if containsHTML && isTitle {
            inputString = "<strong>\(textString)</strong>"
        }

        guard let data = inputString.data(using: .unicode) else {
            return nil
        }

        var options: [NSAttributedString.DocumentReadingOptionKey: Any] = [:]
        options[.documentType] = NSAttributedString.DocumentType.html

        guard let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }

        if textString.isEmpty {
            return nil
        }

        let hasBckColor = !bckColor.isEmpty
        if !hasBckColor && isDarkMode {
            attributedString.updateDefaultTextColor()
        }

        let containsFontSize = inputString.range(of: "font-size") != nil

        let defaultFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        let boldFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)

        if containsHTML && !containsFontSize {
            if isTitle {
                attributedString.setFontFace(with: boldFont)
            } else {
                attributedString.setFontFace(with: defaultFont)
            }
        } else if !containsHTML {
            if isTitle {
                attributedString.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: attributedString.length))
            } else {
                attributedString.addAttribute(.font, value: defaultFont, range: NSRange(location: 0, length: attributedString.length))
            }
        } else {
            attributedString.trimWhiteSpace()
        }

        return attributedString
    }

    func containsHTML(_ value: String) -> Bool {
        return value.range(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", options: .regularExpression) != nil
    }

    func updateDarkModeStatus() {
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                isDarkMode = true
            } else {
                isDarkMode = false
            }
        }
    }
}
