//
//  File.swift
//  
//
//  Created by Shubham Naidu on 13/11/23.
//

import Foundation
import UIKit

extension WEXCarouselPushNotificationViewController{
    
    /// Initializes the view hierarchy with a Carousel Layout.
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
                            notificationContentView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor).isActive = true
                                
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
    
    /// Initializes the view hierarchy and adding a wrapper view and rich content labels container.
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
    
    /// Get the frame size from the Image.
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
    
    /// Render the animation on click of next Image..
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
                    if wasLoaded && !self.shouldScroll{
                        self.addViewEventForIndex(self.current)
                    }
                })
            }
        }
    }
}
