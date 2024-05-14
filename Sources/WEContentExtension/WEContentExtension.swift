import UserNotifications
import UserNotificationsUI
import UIKit

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
        updateActivity(object: true, forKey: WEConstants.COLLAPSED)
        DispatchQueue.main.async {
            self.label?.removeFromSuperview()
            self.currentLayout = nil
            self.notification = nil
        }
    }
    
    open override var canBecomeFirstResponder: Bool {
        if (self.currentLayout != nil){
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
        if notification.request.content.userInfo[WEConstants.SOURCE] as? String == WEConstants.WEBENGAGE {
            self.notification = notification
            isRendering = true
            updateDarkModeStatus()
            WEXCoreUtils.setExtensionDefaults()
            var appGroup = Bundle.main.object(forInfoDictionaryKey: WEConstants.WEX_APP_GROUP) as? String
            
            if appGroup == nil {
                var bundle = Bundle.main
                if bundle.bundleURL.pathExtension == WEConstants.APPEX {
                    bundle = Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
                }
                let bundleIdentifier = bundle.object(forInfoDictionaryKey: WEConstants.CFBUNDLEIDENTIFIER) as? String
                appGroup = "\(WEConstants.GROUP).\(bundleIdentifier ?? "").\(WEConstants.WENOTIFICATIONGROUP)"
            }
            
            richPushDefaults = UserDefaults(suiteName: appGroup)
            
            updateActivity(object: false, forKey: WEConstants.COLLAPSED)
            updateActivity(object: true, forKey: WEConstants.EXPANDED)
            
            if let expandableDetails = notification.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any], let style = expandableDetails[WEConstants.STYLE] as? String {
                currentLayout = layoutForStyle(style)
                currentLayout?.didReceiveNotification(notification)
            }
        }
    }
    
    /// - Parameters:
    ///  - style: The style of the notification.
    ///  - Returns: An instance of WEXRichPushLayout corresponding to the specified style.
    func layoutForStyle(_ style: String) -> WEXRichPushLayout? {
        switch style {
        case WEConstants.CAROUSEL:
            return WEXCarouselPushNotificationViewController(notificationViewController: self)
        case WEConstants.RATING:
            return WEXRatingPushNotificationViewController(notificationViewController: self)
        case WEConstants.BIG_PICTURE:
            return WEXBannerPushNotificationViewController(notificationViewController: self)
        case WEConstants.BIG_TEXT:
            return WEXTextPushNotificationViewController(notificationViewController: self)
        case WEConstants.OVERLAY :
            return WEXOverlayPushNotificationViewController(notificationViewController: self)
        default:
            return nil
        }
    }
    
    public func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            self.currentLayout?.didReceiveNotificationResponse(response, completionHandler: completion)
        }
    }
    
    // Overrides the traitCollectionDidChange method to update the dark mode status.
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDarkModeStatus()
    }
    
    // Returns an activity dictionary for the current notification.
    func getActivityDictionaryForCurrentNotification() -> NSMutableDictionary {
        guard let userInfo = notification?.request.content.userInfo as? [String: Any],
              let expId = userInfo[WEConstants.EXPERIMENT_ID] as? String,
              let notifId = userInfo[WEConstants.NOTIFICATION_ID] as? String else {
            return NSMutableDictionary()
        }
        
        let finalNotifId = "\(expId)|\(notifId)"
        let expandableDetails = userInfo[WEConstants.EXPANDABLEDETAILS]
        let customData = userInfo[WEConstants.CUSTOM_DATA] as? [Any]
        
        let dictionary = (richPushDefaults?.dictionary(forKey: finalNotifId) as? NSMutableDictionary) ?? NSMutableDictionary()
        if dictionary.count == 0 {
            dictionary[WEConstants.EXPERIMENT_ID] = expId
            dictionary[WEConstants.NOTIFICATION_ID] = notifId
            dictionary[WEConstants.EXPANDABLEDETAILS] = expandableDetails
            if let customData = customData {
                dictionary[WEConstants.CUSTOM_DATA] = customData
            }
        }
        return dictionary
    }
    
    /// - Parameters:
    ///   - object: The value to be set for the specified key in the activity dictionary.
    ///   - key: The key under which to store the value in the activity dictionary.
    func updateActivity(object: Any, forKey key: String) {
        if let activityDictionary = getActivityDictionaryForCurrentNotification() as? [String: Any] {
            var updatedActivityDictionary = activityDictionary
            updatedActivityDictionary[key] = object
            setActivityForCurrentNotification(activity: updatedActivityDictionary)
        }
    }
    /// - Parameters:
    ///   - activity: The activity dictionary to be set for the current notification.
    func setActivityForCurrentNotification(activity: [String: Any]) {
        guard let expId = notification?.request.content.userInfo[WEConstants.EXPERIMENT_ID] as? String,
              let notifId = notification?.request.content.userInfo[WEConstants.NOTIFICATION_ID] as? String else {
            return
        }
        
        let finalNotifId = "\(expId)|\(notifId)"
        richPushDefaults?.set(activity, forKey: finalNotifId)
        richPushDefaults?.synchronize()
    }
    /// - Parameters:
    ///   - eventName: The name of the system event.
    ///   - systemData: The system-specific data for the system event.
    ///   - applicationData: The application-specific data for the system event.
    func addSystemEvent(name eventName: String, systemData: [String: Any], applicationData: [String: Any]) {
        addEvent(name: eventName, systemData: systemData, applicationData: applicationData, category: WEConstants.SYSTEM)
    }
    
    /// - Parameters:
    ///   - eventName: The name of the event.
    ///   - systemData: The system-specific data for the event.
    ///   - applicationData: The application-specific data for the event.
    ///   - category: The category of the event.
    func addEvent(name eventName: String, systemData: [String: Any], applicationData: [String: Any], category: String) {
        let customData = notification?.request.content.userInfo[WEConstants.CUSTOM_DATA] as? [Any]
        var customDataDictionary = [String: Any]()
        
        if let customData = customData as? [[String: Any]] {
            for customDataItem in customData {
                if let key = customDataItem["key"] as? String,
                   let value = customDataItem["value"] {
                    customDataDictionary[key] = value
                }
            }
        }
        
        if category == WEConstants.SYSTEM {
            WEXAnalytics.trackEvent(withName: "we_\(eventName)", andValue: [
                WEConstants.SYSTEM_DATA_OVERRIDES: systemData,
                WEConstants.EVENT_DATA_OVERRIDES: customDataDictionary
            ])
        } else {
            WEXAnalytics.trackEvent(withName: eventName, andValue: customDataDictionary)
        }
    }
    
    /// - Parameters:
    ///   - ctaId: The ID of the Call to Action (CTA).
    ///   - actionLink: The action link associated with the CTA.
    func setCTAWithId(_ ctaId: String, andLink actionLink: String) {
        let cta = ["id": ctaId, "actionLink": actionLink]
        updateActivity(object: cta, forKey: "cta")
    }
    
    /// - Parameters:
    ///   - text: The text for which the natural text alignment is to be determined.
    /// Returns: The natural text alignment (left, right, or center).
    func naturalTextAlignmentForText(_ text: String?, forDescription: Bool = false) -> NSTextAlignment {
        guard let text = text, !text.isEmpty else {
            return .left
        }
        let rightToLeftLanguages: Set<String> = ["he", "ar"]
        if !forDescription {
            let preferredLanguages = Locale.preferredLanguages
            let deviceLanguage = preferredLanguages.first
            let primaryLanguage = Locale.components(fromIdentifier: deviceLanguage ?? "")[NSLocale.Key.languageCode.rawValue] as? String ?? ""
            if rightToLeftLanguages.contains(primaryLanguage) {
                return .right
            } else {
                return .left
            }
        } else {
            let chars = differentiateCharsAndEmojis(inputString: text)
            if let firstChar = chars.first {
                if isFirstCharRTL(inputString: String(firstChar)){
                    return .right
                }else {
                    return .left
                }
            } else {
                return .left
            }
        }
    }
    
    /// -  Parameters:
    ///   - textString: The HTML text string to be parsed.
    ///   - isTitle: A flag indicating whether the text is a title.
    ///   - bckColor: The background color associated with the text.
    /// Returns: An NSAttributedString representing the parsed HTML text.
    func getHtmlParsedString(_ textString: String, isTitle: Bool, bckColor: String) -> NSAttributedString? {
        let containsHTML = WEXCoreUtils.containsHTML(textString)
        var inputString = textString
        
        if containsHTML && isTitle {
            inputString = "<strong>\(textString)</strong>"
        }
        
        guard let data = inputString.data(using: .unicode) else {
            return nil
        }
        
        var options: [NSAttributedString.DocumentReadingOptionKey: Any] = [:]
        options[.documentType] = NSAttributedString.DocumentType.html
        
        guard let attributedString = try? NSMutableAttributedString(data: inputString.data(using: .unicode)!,
                                                                    options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                                                                    documentAttributes: nil) else {
            return nil
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.baseWritingDirection = .natural
        attributedString.addAttributes([.paragraphStyle: paragraphStyle],
                                       range: NSRange(location: 0, length: attributedString.length))
        
        
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
    
    // Updates the dark mode status based on the current trait collection.
    func updateDarkModeStatus() {
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                isDarkMode = true
            } else {
                isDarkMode = false
            }
        }
    }
    
    @objc
    open func setUpViews(parentVC:UIViewController){
        parentVC.view.subviews.forEach({$0.isHidden = true})
        parentVC.view.layoutIfNeeded()
        parentVC.addChild(self)
        self.didMove(toParent: self)
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.layoutIfNeeded()
        let viewToAdd = self.view!
        parentVC.view.addSubview(viewToAdd)
        viewToAdd.isHidden = false
        
        
        let heightConstraint = parentVC.view.heightAnchor.constraint(equalTo: self.view.heightAnchor)
        heightConstraint.priority = UILayoutPriority.required - 1
        heightConstraint.isActive = true
        
        NSLayoutConstraint.activate([self.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
                                     self.view.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
                                     self.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor)])
        parentVC.view.layoutIfNeeded()
    }
    
    func isEmoji(character: Character) -> Bool {
        for scalar in character.unicodeScalars {
            if scalar.properties.isEmoji {
                return true
            }
        }
        return false
    }
    
    func differentiateCharsAndEmojis(inputString: String) -> [Character] {
        var chars: [Character] = []
        for char in inputString {
            if !isEmoji(character: char) {
                chars.append(char)
            }
        }
        return (chars)
    }
    
    func isFirstCharRTL(inputString: String) -> Bool {
        guard let firstChar = inputString.first else {
            return false
        }
        let languageCharacterSet = CharacterSet(charactersIn: "\u{05D0}-\u{05EA}\u{0600}-\u{0645}")
        return languageCharacterSet.contains(firstChar.unicodeScalars.first!)
    }
}
