//
//  WEXRichPushLayout.swift
//
//
//  Created by Shubham Naidu on 01/11/23.
//

import Foundation
import UIKit
import UserNotifications
import UserNotificationsUI

class WEXRichPushLayout: NSObject {
    var viewController: WEXRichPushNotificationViewController?
    var view: UIView?

    init(notificationViewController viewController: WEXRichPushNotificationViewController) {
        self.viewController = viewController
        self.view = viewController.view
    }

    func didReceiveNotification(_ notification: UNNotification) { }
    func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {}
}
