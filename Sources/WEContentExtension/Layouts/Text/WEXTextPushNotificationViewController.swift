//
//  WEXTextPushNotificationViewController.swift
//
//
//  Created by Shubham Naidu on 03/11/23.
//


import UIKit
import UserNotificationsUI
import UserNotifications

class WEXTextPushNotificationViewController: WEXRichPushLayout {
    var notification: UNNotification?

    override func didReceiveNotification(_ notification: UNNotification) {
        if let source = notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            self.notification = notification
            initialiseViewHierarchy()
        }
    }

    override func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE{
            completion(.dismissAndForwardAction)
        }
    }
    
    /// Initializes the view hierarchy by setting the background color (if available) and adding a wrapper view and rich content labels container.
    func initialiseViewHierarchy() {
        if #available(iOS 13.0, *) {
            view?.backgroundColor = UIColor.WEXWhiteColor()
        }
        let superViewWrapper = UIView()
        view?.addSubview(superViewWrapper)
        setupLabelsContainer()
    }
}
