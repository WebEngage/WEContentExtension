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
  
}
