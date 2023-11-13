//
//  WEXBannerPushNotificationViewController.swift
//
//
//  Created by Shubham Naidu on 03/11/23.
//
import UIKit
import UserNotifications
import UserNotificationsUI

class WEXBannerPushNotificationViewController: WEXRichPushLayout {

    var notification: UNNotification?

    override func didReceiveNotification(_ notification: UNNotification) {
        if let source = notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            self.notification = notification
            initialiseViewHierarchy()
        }
    }

    override func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            completion(.dismissAndForwardAction)
        }
    }

    func initialiseViewHierarchy() {
        if #available(iOS 13.0, *) {
            view?.backgroundColor = UIColor.WEXWhiteColor()
        }
        
        let superViewWrapper = UIView()
        view?.addSubview(superViewWrapper)
        
        let mainContentView = UIView()
        superViewWrapper.addSubview(mainContentView)
        
        setupBannerImageView()
    }

}
