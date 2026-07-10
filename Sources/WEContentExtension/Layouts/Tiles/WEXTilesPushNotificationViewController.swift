//
//  WEXTilesPushNotificationViewController.swift
//
//
//  Created by Shubham Naidu on 2025.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class WEXTilesPushNotificationViewController: WEXRichPushLayout {

    var notification: UNNotification?
    var tileItems: [[String: Any]] = []

    override func didReceiveNotification(_ notification: UNNotification) {
        if let source = notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            self.notification = notification
            if let expandableDetails = notification.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
               let items = expandableDetails[WEConstants.TILES_ITEMS] as? [[String: Any]], !items.isEmpty {
                tileItems = items
                initialiseViewHierarchy()
            } else if let viewController = viewController {
                // Tiles layout requires at least 1 tile item; fallback to text layout
                let fallback = WEXTextPushNotificationViewController(notificationViewController: viewController)
                viewController.currentLayout = fallback
                fallback.didReceiveNotification(notification)
            }
        }
    }

    override func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            completion(.dismissAndForwardAction)
        }
    }

    func initialiseViewHierarchy() {
        setupTilesView()
    }

    @objc func tileTapped(_ sender: UIButton) {
        guard sender.tag < tileItems.count else { return }
        let item = tileItems[sender.tag]

        let id = item["id"] as? String ?? ""
        let actionLink = item[WEConstants.ACTION_LINK] as? String ?? ""
        viewController?.setCTAWithId(id, andLink: actionLink)

        if let ctaAttributeValue = item[WEConstants.CTA_ATTRIBUTE_VALUE] as? String,
           ctaAttributeValue == WEConstants.CTA_DISMISS,
           let identifier = notification?.request.identifier {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
            viewController?.extensionContext?.dismissNotificationContentExtension()
        } else {
            viewController?.extensionContext?.performNotificationDefaultAction()
        }
    }
}
