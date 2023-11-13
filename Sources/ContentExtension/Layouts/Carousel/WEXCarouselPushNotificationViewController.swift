//
//  WEXCarouselPushNotificationViewController.swift
//
//
//  Created by Shubham Naidu on 06/11/23.
//

import Foundation
import UIKit
import UserNotifications
import UserNotificationsUI

let WEX_EVENT_NAME_PUSH_NOTIFICATION_ITEM_VIEW = "push_notification_item_view"
let MAIN_VIEW_TO_SUPER_VIEW_WIDTH_RATIO: Float = 0.7
let MAIN_VIEW_TO_SUPER_VIEW_VERTICAL_MARGINS: Float = 5
let DESCRIPTION_VIEW_HEIGHT: Float = 50
let DESCRIPTION_VIEW_ALPHA: CGFloat = 0.5
let INTER_VIEW_MARGINS: Float = 10
let SIDE_VIEWS_FADE_ALPHA: CGFloat = 0.75
let SLIDE_ANIMATION_DURATION: TimeInterval = 0.5
let PORTRAIT_ASPECT: Float = 1.0
let NOTIFICATION_CONTENT_BAR_HEIGHT: Float = 50.0

enum WEXCarouselFrameLocation: Int {
    case WEXPreviousLeft = -2
    case WEXLeft = -1
    case WEXCurrent = 0
    case WEXRight = 1
    case WEXNextRight = 2
}

class WEXCarouselPushNotificationViewController: WEXRichPushLayout {
    
    var current: Int = 0
    var images: [UIImage] = []
    var wasLoaded: [Bool] = []
    var carouselItems: [Any] = []
    var viewContainers: [AnyObject] = []
    var imageViews: [UIImageView] = []
    var descriptionViews: [UIView] = []
    var descriptionLabels: [UILabel] = []
    var alphaViews: [UIView] = []
    
    var notification: UNNotification?
    var errorImage: UIImage?
    var loadingImage: UIImage?
    var richPushDefaults: UserDefaults?
    var nextViewIndexToReturn: Int = 0
    var isRendering: Bool = false
    var scrollTimer: Timer?
    var shouldScroll: Bool = false
    
    override func didReceiveNotification(_ notification: UNNotification) {
        if let source = notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            isRendering = true
            self.notification = notification
            current = 0
            
            if let expandedDetails = notification.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any] {
                if let items = expandedDetails[WEConstants.ITEMS] as? [[String: Any]], !items.isEmpty {
                    carouselItems = items
                    images = []
                    wasLoaded = []
                    let downloadedCount = notification.request.content.attachments.count
                    setCTAForIndex(0)
                    var firstImageAdded = false
                    
                    if downloadedCount == 0 {
                        if let carouselItem = carouselItems[0] as? [String: Any] ,let imageURL = carouselItem[WEConstants.IMAGE] as? String, let imageUrl = URL(string: imageURL), let imageData = try? Data(contentsOf: imageUrl) {
                            if let image = UIImage(data: imageData) {
                                images.append(image)
                                wasLoaded.append(true)
                                addViewEventForIndex(0, isFirst: true)
                            } else {
                                images.append(getErrorImage()!)
                                wasLoaded.append(false)
                            }
                            firstImageAdded = true
                        }
                    }
                    
                    for i in (firstImageAdded ? 1 : 0)..<items.count {
                        wasLoaded.append(false)
                        
                        if i < downloadedCount {
                            if #available(iOS 10.0, *) {
                                if let attachmentValue = notification.request.content.attachments.first(where: { $0.identifier == "\(i)" }) {
                                    if attachmentValue.url.startAccessingSecurityScopedResource() {
                                        if let imageData = try? Data(contentsOf: attachmentValue.url), let image = UIImage(data: imageData) {
                                            images.append(image)
                                            wasLoaded[i] = true
                                            if i == 0 {
                                                addViewEventForIndex(0, isFirst: true)
                                            }
                                            attachmentValue.url.stopAccessingSecurityScopedResource()
                                        } else {
                                            images.append(getErrorImage()!)
                                        }
                                    }
                                }
                            } else {
                                print("Expected to be running iOS version 10 or above")
                            }
                        } else {
                            images.append(getLoadingImage()!)
                        }
                    }
                    initialiseCarouselForNotification(notification)
                    setupAutoScroll(notification)
                    
                    if downloadedCount < items.count {
                        downloadRemaining(from: downloadedCount)
                    }
                }
            }
        }
    }
    
    func downloadRemaining(from downloadFromIndex: Int) {
        for i in downloadFromIndex..<carouselItems.count {
            DispatchQueue.global(qos: .userInitiated).async {
                if let carouselItem = self.carouselItems[0] as? [String: Any] ,let imageURL = carouselItem[WEConstants.IMAGE] as? String,
                   let imageUrl = URL(string: imageURL),
                   let imageData = try? Data(contentsOf: imageUrl),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.images[i] = image
                        self.wasLoaded[i] = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images[i] = self.getErrorImage()!
                        self.wasLoaded[i] = false
                    }
                }
            }
        }
    }
    
    func setupAutoScroll(_ notification: UNNotification) {
        if let expandableDetails = notification.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
           let scrollTime = expandableDetails["ast"] as? String,
           !scrollTime.isEmpty {
            
            if let intervalInMili = Float(scrollTime) {
                let intervalSeconds = Float(intervalInMili / 1000.0)
                
                // Scroll if interval is more than 0
                if intervalSeconds > 0 {
                    shouldScroll = true
                    DispatchQueue.main.async {
                        self.scrollTimer?.invalidate()
                        self.scrollTimer = Timer.scheduledTimer(
                            timeInterval: TimeInterval(intervalSeconds),
                            target: self,
                            selector: #selector(self.scrollContent(_:)),
                            userInfo: notification,
                            repeats: true
                        )
                    }
                }
            }
        }
    }
    
    @objc func scrollContent(_ scrollTimer: Timer) {
        if shouldScroll {
            if let notification = scrollTimer.userInfo as? UNNotification {
                renderAnimated(notification)
            } else {
                stopScrollTimer()
            }
        } else {
            stopScrollTimer()
        }
    }
    
    func stopScrollTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    func initialiseCarouselForNotification(_ notification: UNNotification) {
        if notification.request.content.userInfo[WEConstants.SOURCE] as? String == WEConstants.WEBENGAGE {
            initialiseViewContainers()
            
            let mainViewToSuperViewWidthRatio = MAIN_VIEW_TO_SUPER_VIEW_WIDTH_RATIO
            let verticalMargins = MAIN_VIEW_TO_SUPER_VIEW_VERTICAL_MARGINS
            
            guard let superViewWidth = self.view?.frame.size.width else {
                return
            }
            
            var viewWidth = Float(superViewWidth) * mainViewToSuperViewWidthRatio - 2 * verticalMargins
            var viewHeight = viewWidth
            
            // for portrait
            var superViewHeight = viewHeight + 2 * verticalMargins
            
            if let expandableDetails = notification.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String : Any]{
                if let colorHex = expandableDetails[WEConstants.BLACKCOLOR] as? String{
                    if #available(iOS 13.0, *) {
                        self.view?.backgroundColor = UIColor.colorFromHexString(colorHex, defaultColor: UIColor.WEXWhiteColor())
                    }
                    if #available(iOS 13.0, *) {
                        self.viewController?.view.backgroundColor = UIColor.colorFromHexString(colorHex, defaultColor: UIColor.WEXWhiteColor())
                    }}
                
                
                if let mode = expandableDetails[WEConstants.MODE] as? String {
                    let isPortrait = mode == WEConstants.POTRAIT
                    
                    if !isPortrait {
                        viewWidth = Float(superViewWidth)
                        viewHeight = viewWidth * WEConstants.LANDSCAPE_ASPECT
                        superViewHeight = viewHeight
                    }
                }
                
                let count = self.carouselItems.count
                let current = self.current
                let previous = (current + count - 1) % count
                let next = (current + 1) % count
                let nextRight = (current + 2) % count
                
                let previousView = self.viewAtPosition(previous)
                previousView.frame = self.frameForViewPosition(.WEXLeft)
                
                let currentView = self.viewAtPosition(current)
                currentView.frame = self.frameForViewPosition(.WEXCurrent)
                
                let nextView = self.viewAtPosition(next)
                nextView.frame = self.frameForViewPosition(.WEXRight)
                
                let nextRightView = self.viewAtPosition(nextRight)
                nextRightView.frame = self.frameForViewPosition(.WEXNextRight)
                
                self.view?.addSubview(previousView)
                self.view?.addSubview(currentView)
                self.view?.addSubview(nextView)
                self.view?.addSubview(nextRightView)
                
                if let mode = expandableDetails[WEConstants.MODE] as? String {
                    let isPortrait = mode == WEConstants.POTRAIT
                    if isPortrait {
                        previousView.subviews[2].alpha = SIDE_VIEWS_FADE_ALPHA
                        nextView.subviews[2].alpha = SIDE_VIEWS_FADE_ALPHA
                    }
                }
                
                let topSeparator = UIView(frame: CGRect(x: 0.0, y: 0.0, width: superViewWidth, height: 0.5))
                if #available(iOS 13.0, *) {
                    topSeparator.backgroundColor = UIColor.WEXGreyColor()
                }
                
                let bottomSeparator = UIView(frame: CGRect(x: 0.0, y: CGFloat(superViewHeight) - 0.5, width: superViewWidth, height: 0.5))
                if let colorHex = expandableDetails[WEConstants.BLACKCOLOR] as? String{
                    if #available(iOS 13.0, *) {
                        bottomSeparator.backgroundColor = UIColor.colorFromHexString(colorHex, defaultColor: UIColor.WEXGreyColor())
                    }}
                
                if let extensionAttributes = Bundle.main.object(forInfoDictionaryKey: "NSExtension") as? [String: Any],
                   let extensionAttribute = extensionAttributes["NSExtensionAttributes"] as? [String:Any],
                   let defaultContentHidden = extensionAttribute["UNNotificationExtensionDefaultContentHidden"] as? Bool {
                    
                    self.view?.addSubview(topSeparator)
                    self.view?.addSubview(bottomSeparator)
                    
                    if defaultContentHidden {
                        var richTitle = expandableDetails[WEConstants.RICHTITLE] as? String
                        var richSub = expandableDetails[WEConstants.RICHSUBTITLE] as? String
                        var richMessage = expandableDetails[WEConstants.RICHMESSAGE] as? String
                        
                        var isRichTitle = false, isRichSubtitle = false, isRichMessage = false
                        
                        if let richTitle = richTitle, !richTitle.isEmpty {
                            isRichTitle = true
                        }
                        if let richSub = richSub, !richSub.isEmpty {
                            isRichSubtitle = true
                        }
                        if let richMessage = richMessage, !richMessage.isEmpty {
                            isRichMessage = true
                        }
                        
                        if !isRichTitle {
                            richTitle = self.notification?.request.content.title
                        }
                        if !isRichSubtitle {
                            richSub = self.notification?.request.content.subtitle
                        }
                        if !isRichMessage {
                            richMessage = self.notification?.request.content.body
                        }
                        
                        let colorHex = expandableDetails[WEConstants.BLACKCOLOR] as? String
                        
                        let richTitleLabel = UILabel()
                        if let richTitle = richTitle{
                            richTitleLabel.attributedText = self.viewController?.getHtmlParsedString(richTitle, isTitle: true, bckColor: colorHex ?? WEConstants.WHITECOLOR)
                            if let alignment = self.viewController?.naturalTextAligmentForText(richTitleLabel.text){
                                richTitleLabel.textAlignment = alignment
                            }
                        }
                        let richSubLabel = UILabel()
                        if let richSub = richSub {
                            richSubLabel.attributedText = self.viewController?.getHtmlParsedString(richSub, isTitle: true, bckColor: colorHex ?? WEConstants.WHITECOLOR)
                            if let alignment = self.viewController?.naturalTextAligmentForText(richSubLabel.text){
                                richSubLabel.textAlignment = alignment
                            }
                        }
                        
                        let richBodyLabel = UILabel()
                        if let richMessage = richMessage {
                            richBodyLabel.attributedText = self.viewController?.getHtmlParsedString(richMessage, isTitle: false, bckColor: colorHex ?? WEConstants.WHITECOLOR)
                            if let alignment = self.viewController?.naturalTextAligmentForText( richBodyLabel.text){
                                richBodyLabel.textAlignment = alignment
                                richBodyLabel.numberOfLines = 0
                            }
                        }
                        
                        let notificationContentView = UIView()
                        if #available(iOS 13.0, *) {
                            notificationContentView.backgroundColor = UIColor.colorFromHexString(colorHex ?? WEConstants.WHITECOLOR, defaultColor: UIColor.WEXWhiteColor())
                        }
                        
                        notificationContentView.addSubview(richTitleLabel)
                        notificationContentView.addSubview(richSubLabel)
                        notificationContentView.addSubview(richBodyLabel)
                        
                        self.view?.addSubview(notificationContentView)
                        
                        if let view = self.view, let viewController = self.viewController{
                                notificationContentView.translatesAutoresizingMaskIntoConstraints = false
                                notificationContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                                notificationContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
                                notificationContentView.topAnchor.constraint(equalTo: bottomSeparator.bottomAnchor).isActive = true
                            notificationContentView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
                                
                                richTitleLabel.translatesAutoresizingMaskIntoConstraints = false
                                richTitleLabel.leadingAnchor.constraint(equalTo: notificationContentView.leadingAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
                                richTitleLabel.trailingAnchor.constraint(equalTo: notificationContentView.trailingAnchor, constant: -WEConstants.CONTENT_PADDING).isActive = true
                                richTitleLabel.topAnchor.constraint(equalTo: notificationContentView.topAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
                                           
                                richSubLabel.translatesAutoresizingMaskIntoConstraints = false
                                richSubLabel.leadingAnchor.constraint(equalTo: notificationContentView.leadingAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
                                richSubLabel.trailingAnchor.constraint(equalTo: notificationContentView.trailingAnchor, constant: -WEConstants.CONTENT_PADDING).isActive = true
                                richSubLabel.topAnchor.constraint(equalTo: richTitleLabel.bottomAnchor).isActive = true
                                
                                richBodyLabel.translatesAutoresizingMaskIntoConstraints = false
                                richBodyLabel.leadingAnchor.constraint(equalTo: notificationContentView.leadingAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
                                richBodyLabel.trailingAnchor.constraint(equalTo: notificationContentView.trailingAnchor, constant: -WEConstants.CONTENT_PADDING).isActive = true
                                richBodyLabel.topAnchor.constraint(equalTo: richSubLabel.bottomAnchor).isActive = true
                            richBodyLabel.bottomAnchor.constraint(equalTo: notificationContentView.bottomAnchor, constant: -WEConstants.CONTENT_PADDING).isActive = true
                        }
                    } else {
                        if let height = self.view?.bounds.size.height{
                            self.viewController?.preferredContentSize = CGSize(width: superViewWidth, height: height)
                        }
                        let logMessage = "The `UNNotificationExtensionDefaultContentHidden` flag in your Info.plist file is either not set or set to NO. Since v3.4.17 of WebEngage SDK, this flag MUST be set to YES, failing which other layouts (Rating etc) will not render properly. Refer http://docs.webengage.com/docs/ios-10-rich-push-notifications-integration"
                        print(logMessage)
                    }
                    self.isRendering = false
                }
            }
        }
    }
    
    func initialiseViewContainers() {
        self.viewContainers = [UIView](repeating: UIView(), count: 4)
        self.imageViews = [UIImageView](repeating: UIImageView(), count: 4)
        self.descriptionViews = [UIView](repeating: UIView(), count: 4)
        self.descriptionLabels = [UILabel](repeating: UILabel(), count: 4)
        self.alphaViews = [UIView](repeating: UIView(), count: 4)
        
        for i in 0..<4 {
            let view = UIView()
            view.accessibilityIdentifier = "view-\(i)"
            self.viewContainers[i] = view
            self.imageViews[i] = UIImageView()
            self.descriptionViews[i] = UIView()
            self.descriptionLabels[i] = UILabel()
            self.alphaViews[i] = UIView()
        }
        
        self.nextViewIndexToReturn = 0
    }
    
    func getImageFrameSize() -> CGSize {
        let mainViewToSuperViewWidthRatio = MAIN_VIEW_TO_SUPER_VIEW_WIDTH_RATIO
        let verticalMargins = MAIN_VIEW_TO_SUPER_VIEW_VERTICAL_MARGINS
        
        guard let superViewWidth = self.view?.frame.size.width else {
            return CGSize()
        }
        
        var viewWidth: Float
        var viewHeight: Float
        
        if let expandableDetails = self.notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any] , let mode = expandableDetails[WEConstants.MODE] as? String {
            let isPortrait = mode == WEConstants.POTRAIT
            
            if isPortrait {
                viewWidth = Float(superViewWidth) * mainViewToSuperViewWidthRatio - 2 * verticalMargins
                viewHeight = viewWidth
            } else {
                viewWidth = Float(superViewWidth)
                viewHeight = viewWidth * WEConstants.LANDSCAPE_ASPECT
            }
        } else {
            viewWidth = Float(superViewWidth)
            viewHeight = viewWidth * WEConstants.LANDSCAPE_ASPECT
        }
        
        return CGSize(width: Double(viewWidth), height: Double(viewHeight))
    }
    
    func renderAnimated(_ notification: UNNotification) {
        if notification.request.content.userInfo[WEConstants.SOURCE] as? String == WEConstants.WEBENGAGE {
            if let expandableDetails = notification.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String : Any], let mode = expandableDetails[WEConstants.MODE] as? String {
                let count = self.carouselItems.count
                let currentMain = self.current
                let currentLeft = (currentMain + count - 1) % count
                let currentRight = (currentMain + 1) % count
                let nextRight = (currentRight + 1) % count
                
                self.isRendering = true
                
                let currentLeftView = self.viewAtPosition(currentLeft)
                currentLeftView.frame = self.frameForViewPosition(.WEXLeft)
                
                let currentMainView = self.viewAtPosition(currentMain)
                currentMainView.frame = self.frameForViewPosition(.WEXCurrent)
                
                let currentRightView = self.viewAtPosition(currentRight)
                currentRightView.frame = self.frameForViewPosition(.WEXRight)
                
                let nextRightView = self.viewAtPosition(nextRight)
                nextRightView.frame = self.frameForViewPosition(.WEXNextRight)
                
                let isPortrait = mode == WEConstants.POTRAIT
                var slideBy: CGFloat = 0.0
                
                if isPortrait {
                    slideBy = currentMainView.frame.size.width + CGFloat(INTER_VIEW_MARGINS)
                    nextRightView.subviews[2].alpha = 0.0
                } else {
                    slideBy = currentMainView.frame.size.width
                }
                
                UIView.animate(withDuration: SLIDE_ANIMATION_DURATION, animations: {
                    self.slideLeft(currentLeftView, by: slideBy)
                    self.slideLeft(currentMainView, by: slideBy)
                    self.slideLeft(currentRightView, by: slideBy)
                    
                    if isPortrait {
                        self.slideLeft(nextRightView, by: slideBy)
                        currentMainView.subviews[2].alpha = SIDE_VIEWS_FADE_ALPHA
                        currentRightView.subviews[2].alpha = 0.0
                        nextRightView.subviews[2].alpha = SIDE_VIEWS_FADE_ALPHA
                    }
                }, completion: { (finished) in
                    self.current = (self.current + 1) % count
                    self.isRendering = false
                    self.setCTAForIndex(self.current)
                    
                    let wasLoaded = self.wasLoaded[self.current]
                    if wasLoaded {
                        self.addViewEventForIndex(self.current)
                    }
                })
            }
        }
    }
    
    func getActivityDictionaryForCurrentNotification() -> [String: Any]? {
        if let viewController = self.viewController {
            return viewController.getActivityDictionaryForCurrentNotification() as? [String : Any]
        }
        return nil
    }
    
    func writeObject(_ object: Any, withKey key: String) {
        if let viewController = self.viewController {
            viewController.updateActivity(object: object, forKey: key)
        }
    }
    
    func slideLeft(_ view: UIView, by slide: CGFloat) {
        var finalFrame = view.frame
        finalFrame.origin.x -= slide
        view.frame = finalFrame
    }
    
    override func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if response.notification.request.content.userInfo[WEConstants.SOURCE] as? String == WEConstants.WEBENGAGE {
            print("PUSHDEBUG: ResponseClicked: \(response.actionIdentifier)")
            var dismissed = false
            
            if isRendering {
                return
            }
            
            if response.actionIdentifier == "WEG_NEXT" {
                shouldScroll = false
                renderAnimated(response.notification)
            } else if response.actionIdentifier == "WEG_PREV" {
                // Handle "WEG_PREV" action if needed
            } else if response.actionIdentifier == "WEG_LAUNCH_APP" {
                if #available(iOS 10.0, *) {
                    completion(.dismissAndForwardAction)
                } else {
                    print("Expected to be running iOS version 10 or above")
                }
                return
            } else {
                dismissed = true
            }
            
            if dismissed {
                writeObject(NSNumber(value: true), withKey: "closed")
                if #available(iOS 10.0, *) {
                    completion(.dismiss)
                } else {
                    print("Expected to be running iOS version 10 or above")
                }
            } else {
                if #available(iOS 10.0, *) {
                    completion(.doNotDismiss)
                } else {
                    print("Expected to be running iOS version 10 or above")
                }
            }
        }
    }
    
    func viewAtPosition(_ index: Int) -> UIView {
        let cachedViewIndex = cachedViewsIndexForViewAtIndex(index)
        var viewToReturn: UIView = viewContainers[cachedViewIndex] as! UIView
        
        let mainViewToSuperViewWidthRatio = MAIN_VIEW_TO_SUPER_VIEW_WIDTH_RATIO
        let verticalMargins = MAIN_VIEW_TO_SUPER_VIEW_VERTICAL_MARGINS
        guard let superViewWidth = self.view?.frame.size.width else{
            return UIView()
        }
        
        var viewWidth = Float(superViewWidth) * mainViewToSuperViewWidthRatio - 2 * verticalMargins
        var viewHeight = viewWidth
        let descriptionViewHeight = DESCRIPTION_VIEW_HEIGHT
        
        if let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any], let mode = expandableDetails[WEConstants.MODE] as? String, mode != WEConstants.POTRAIT {
            viewWidth = Float(superViewWidth)
            viewHeight = viewWidth * WEConstants.LANDSCAPE_ASPECT
        }
        let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any]
        let colorHex = expandableDetails?[WEConstants.BLACKCOLOR] as? String ?? ""
        if #available(iOS 13.0, *) {
            viewToReturn.backgroundColor = UIColor.colorFromHexString(colorHex, defaultColor: UIColor.WEXGreyColor())
        }
        
        let carouselItem = carouselItems[index] as? [String : Any]
        var viewContainer: UIView = viewToReturn
        let image = images[index]
        
        let imageView = imageViews[cachedViewIndex]
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: Double(viewWidth), height: Double(viewHeight))
        
        imageView.image = image
        
        imageView.contentMode = .scaleAspectFill
        
        let descriptionView = descriptionViews[cachedViewIndex]
        let yPos = Double(viewHeight - descriptionViewHeight)
        descriptionView.frame = CGRect(x: 0, y:yPos , width: Double(viewWidth), height: Double(descriptionViewHeight))
        descriptionView.alpha = DESCRIPTION_VIEW_ALPHA
        if #available(iOS 13.0, *) {
            descriptionView.backgroundColor = UIColor.WEXWhiteColor()
        }
        
        let descriptionLabel = descriptionLabels[cachedViewIndex]
        descriptionLabel.frame = CGRect(x: 10.0, y: 10.0, width: descriptionView.frame.size.width - 10.0, height: descriptionView.frame.size.height - 10.0)
        
        descriptionLabel.text = carouselItem?["actionText"] as? String
        descriptionLabel.textAlignment = .center
        if #available(iOS 13.0, *) {
            descriptionLabel.textColor = UIColor.WEXLabelColor()
        }
        
        descriptionView.addSubview(descriptionLabel)
        viewContainer.addSubview(imageView)
        viewContainer.addSubview(descriptionView)
        
        if let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any], let mode = expandableDetails[WEConstants.MODE] as? String, mode == WEConstants.POTRAIT {
            viewContainer.layer.cornerRadius = 8.0
            viewContainer.clipsToBounds = true
            
            let alphaView = alphaViews[cachedViewIndex]
            alphaView.frame = CGRect(x: 0.0, y: 0.0, width: Double(viewWidth), height: Double(viewHeight))
            alphaView.alpha = 0.0
            if #available(iOS 13.0, *) {
                alphaView.backgroundColor = UIColor.WEXWhiteColor()
            }
            viewContainer.addSubview(alphaView)
        }
        
        return viewContainer
    }
    
    func cachedViewsIndexForViewAtIndex(_ index: Int) -> Int {
        let returnIndex = nextViewIndexToReturn
        nextViewIndexToReturn = (nextViewIndexToReturn + 1) % viewContainers.count
        return returnIndex
    }
    
    func frameForViewPosition(_ frameLocation: WEXCarouselFrameLocation) -> CGRect {
        let mainViewToSuperViewWidthRatio = MAIN_VIEW_TO_SUPER_VIEW_WIDTH_RATIO
        let verticalMargins = MAIN_VIEW_TO_SUPER_VIEW_VERTICAL_MARGINS
        var interViewMargins = INTER_VIEW_MARGINS
        
        guard let superViewWidth = self.view?.frame.size.width else{
            return CGRect()
        }
        var viewWidth = Float(superViewWidth) * mainViewToSuperViewWidthRatio - 2 * verticalMargins
        var viewHeight = viewWidth
        
        var currentViewX = (1.0 - mainViewToSuperViewWidthRatio) / 2.0 * Float(superViewWidth)
        var currentViewY = verticalMargins
        
        if let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String : Any], let mode = expandableDetails[WEConstants.MODE] as? String, mode != WEConstants.POTRAIT {
            viewWidth = Float(superViewWidth)
            viewHeight = viewWidth * WEConstants.LANDSCAPE_ASPECT
            currentViewX = 0.0
            currentViewY = 0.0
            interViewMargins = 0.0
        }
        let x = currentViewX + Float(frameLocation.rawValue) * interViewMargins + Float(frameLocation.rawValue) * viewWidth
        return  CGRect(x: CGFloat(x), y: CGFloat(currentViewY), width: CGFloat(viewWidth), height: CGFloat(viewHeight))
    }
    
    func addViewEventForIndex(_ index: Int) {
        addViewEventForIndex(index, isFirst: false)
    }
    
    func addViewEventForIndex(_ index: Int, isFirst first: Bool) {
        if let userInfo = notification?.request.content.userInfo,
           let expandableDetails = userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
           let items = expandableDetails[WEConstants.ITEMS] as? [[String: Any]],
           items.count > index,
           let expId = userInfo[WEConstants.EXPERIMENT_ID] as? String,
           let notifId = userInfo[WEConstants.NOTIFICATION_ID] as? String {
            
            let callToAction = items[index]["id"] as? String ?? ""
            let ctaIdPrev = first ? "UNKNOWN" : items[(index + items.count - 1) % items.count]["id"] as? String ?? ""
            
            if let viewController = self.viewController {
                viewController.addSystemEvent(name: WEX_EVENT_NAME_PUSH_NOTIFICATION_ITEM_VIEW, systemData: [
                    "id": notifId,
                    WEConstants.EXPERIMENT_ID: expId,
                    "call_to_action": callToAction,
                    "navigated_from": ctaIdPrev
                ], applicationData: [:])
            }
        }
    }
    
    func setCTAForIndex(_ index: Int) {
        if let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
           let items = expandableDetails[WEConstants.ITEMS] as? [String: Any] {
            let keys = Array(items.keys)
            if index < keys.count, let viewController = self.viewController {
                let key = keys[index]
                if let item = items[key] as? [String: Any] {
                    let ctaId = item["id"] as? String ?? ""
                    let actionLink = item[WEConstants.ACTION_LINK] as? String ?? ""
                    viewController.setCTAWithId(ctaId, andLink: actionLink)
                }
            }
        }
    }
    
    func getLoadingImage() -> UIImage? {
        if self.loadingImage == nil {
            let size = getImageFrameSize()
            let width = size.width
            let height = size.height
            let center = CGPoint(x: width / 2.0, y: height / 2.0)
            let holeWidth: CGFloat = 16.0
            let topBottomBarExtra: CGFloat = 10.0
            let margins: CGFloat = 20.0
            
            UIGraphicsBeginImageContext(size)
            self.loadingImage?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            if let context = UIGraphicsGetCurrentContext() {
                context.setLineCap(.round)
                context.setLineWidth(10.0)
                //                context.setRGBStrokeColor(0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).setStroke()
                context.setBlendMode(.normal)
                
                // Top Bar
                context.move(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0 - topBottomBarExtra, y: margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0 + topBottomBarExtra, y: margins))
                
                // Left Part
                context.move(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: margins))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: (height - 2 * margins) / 3.0 + margins))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0, y: center.y))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: center.y + (height - 2 * margins) / 6.0))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: height - margins))
                
                // Right Part
                context.move(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: (height - 2 * margins) / 3.0 + margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0, y: center.y))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: center.y + (height - 2 * margins) / 6.0))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: height - margins))
                
                // BottomBar
                context.move(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0 - topBottomBarExtra, y: height - margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0 + topBottomBarExtra, y: height - margins))
                
                context.strokePath()
                self.loadingImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                UIGraphicsBeginImageContext(size)
                self.loadingImage?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
                context.setLineCap(.round)
                context.setLineWidth(5.0)
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).setStroke()
                context.setBlendMode(.normal)
                
                let dx: CGFloat = 8.0
                let dy: CGFloat = 8.0
                
                for i in 1...4 {
                    let mid = (i + 1) / 2
                    var x: CGFloat
                    let yTop = center.y - CGFloat(i) * dy
                    let yBottom = center.y + CGFloat(i) * dy
                    
                    for j in 1...i {
                        if i % 2 == 0 {
                            x = center.x - (CGFloat(mid - j) * dx + dx / 2.0)
                        } else {
                            x = center.x - CGFloat(mid - j) * dx
                        }
                        
                        context.move(to: CGPoint(x: x, y: yTop))
                        context.addLine(to: CGPoint(x: x, y: yTop))
                        context.move(to: CGPoint(x: x, y: yBottom))
                        context.addLine(to: CGPoint(x: x, y: yBottom))
                    }
                }
                
                context.strokePath()
                self.loadingImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
        return self.loadingImage
    }
    
    func getErrorImage() -> UIImage? {
        let size = getImageFrameSize()
        
        if self.errorImage == nil {
            let width = size.width
            let height = size.height
            let startPoint = CGPoint(x: width / 2.0, y: height / 4.0)
            let rightPoint = CGPoint(x: width / 2.0 + height / 3.464, y: 0.75 * height)
            let leftPoint = CGPoint(x: width / 2.0 - height / 3.464, y: 0.75 * height)
            
            UIGraphicsBeginImageContext(size)
            self.errorImage?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            
            if let context = UIGraphicsGetCurrentContext() {
                context.setLineCap(.round)
                context.setLineWidth(10.0)
                //                context.setRGBStrokeColor(0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).setStroke()
                context.setBlendMode(.normal)
                
                context.move(to: startPoint)
                context.addLine(to: leftPoint)
                context.addLine(to: rightPoint)
                context.addLine(to: startPoint)
                
                context.move(to: CGPoint(x: startPoint.x, y: startPoint.y + 40))
                context.addLine(to: CGPoint(x: startPoint.x, y: rightPoint.y - 40))
                
                context.move(to: CGPoint(x: startPoint.x, y: rightPoint.y - 20))
                context.addLine(to: CGPoint(x: startPoint.x, y: rightPoint.y - 20))
                
                context.strokePath()
                self.errorImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
        return self.errorImage
    }
    
}
