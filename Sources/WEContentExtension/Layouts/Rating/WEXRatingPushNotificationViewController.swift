//
//  WEXRatingPushNotificationViewController.swift
//
//
//  Created by Shubham Naidu on 05/11/23.
//

import Foundation
import UIKit
import UserNotificationsUI


@available(iOS 10.0, *)
class WEXRatingPushNotificationViewController: WEXRichPushLayout, WEXRatingInputProvider {
    func provideInputView() -> UIView? { inputView() }
    var pickerView: UIPickerView?
    var notification: UNNotification?
    var pickerManager: StarPickerManager?
    var selectedLabel: UILabel?
    var unselectedLabel: UILabel?
    var labelsWrapper: UIView?
    var selectedCount: Int = 0
    var noOfStars: UInt = 0
    let STAR_BAR_HEIGHT: CGFloat = 50
    let STAR_FONT_SIZE: CGFloat = 30
    let WEX_RATING_SUBMITTED_EVENT_NAME = "push_notification_rating_submitted"
    let MAX_DESCRIPTION_LINE_COUNT = 3
    let TEXT_PADDING: CGFloat = 10
    private var cachedInputView: UIView?
   
    @objc func canBecomeFirstResponder() -> Bool {
        return true
    }

    @objc func inputView() -> UIView? {
        if let cached = cachedInputView {
            return cached
        }

        let containerHeight: CGFloat = 216 + 50
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: containerHeight))
        if #available(iOS 13.0, *) {
            container.backgroundColor = .systemBackground
        } else {
            container.backgroundColor = .white
        }

        let picker = self.pickerView ?? UIPickerView()
        picker.frame = CGRect(x: 0, y: 0, width: 320, height: 216)
        picker.autoresizingMask = [.flexibleWidth]
        container.addSubview(picker)

        let doneBar = UIView(frame: CGRect(x: 0, y: 216, width: 320, height: 50))
        doneBar.autoresizingMask = [.flexibleWidth]
        if #available(iOS 13.0, *) {
            doneBar.backgroundColor = .secondarySystemBackground
        } else {
            doneBar.backgroundColor = .groupTableViewBackground
        }
        container.addSubview(doneBar)

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        if #available(iOS 13.0, *) {
            doneButton.setTitleColor(.link, for: .normal)
        } else {
            doneButton.setTitleColor(.systemBlue, for: .normal)
        }
        doneButton.frame = CGRect(x: doneBar.bounds.width - 70, y: 0, width: 60, height: 50)
        doneButton.autoresizingMask = [.flexibleLeftMargin]
        doneButton.addTarget(self, action: #selector(doneButtonClicked(_:)), for: .touchUpInside)
        doneBar.addSubview(doneButton)

        cachedInputView = container
        return container
    }

    override func didReceiveNotification(_ notification: UNNotification) {
        cachedInputView = nil
        if let userInfo = notification.request.content.userInfo as? [String: Any],
           let source = userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            self.notification = notification
            initialiseViewHierarchy()
            
            self.pickerManager = StarPickerManager(notification: notification)
            
            self.pickerView = UIPickerView()
            self.pickerView?.backgroundColor = UIColor.black
            
            self.pickerView?.dataSource = self.pickerManager
            self.pickerView?.delegate = self.pickerManager
            
            if let noOfStars = userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any]?,
               let ratingScale = noOfStars?[WEConstants.RATING_SCALE] as? Int {
                self.pickerView?.selectRow(ratingScale / 2, inComponent: 0, animated: false)
            }
        }
    }
    
    override func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo[WEConstants.SOURCE] as? String, source == WEConstants.WEBENGAGE {
            
            var completionOption: UNNotificationContentExtensionResponseOption = .doNotDismiss
            
            if response.actionIdentifier == "WEG_CHOOSE_RATING" {
                viewController?.becomeFirstResponder()
            } else if response.actionIdentifier == "WEG_SUBMIT_RATING" {
                if selectedCount > 0 {
                    if let userInfo = notification?.request.content.userInfo as? [String: Any],
                       let expandableDetails = userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
                       let expId = userInfo[WEConstants.EXPERIMENT_ID] as? String,
                       let notifId = userInfo[WEConstants.NOTIFICATION_ID] as? String {
                        
                        var systemData: [String: Any] = [
                            "id": notifId,
                            WEConstants.EXPERIMENT_ID: expId
                        ]
                        
                        if let submitCTA = expandableDetails[WEConstants.SUBMIT_CTA] as? [String: Any],
                           let submitCTAId = submitCTA["id"] as? String,
                           let submitCTALink = submitCTA[WEConstants.ACTION_LINK] as? String {
                            
                            systemData["call_to_action"] = submitCTAId
                            viewController?.setCTAWithId(submitCTAId, andLink: submitCTALink)
                        }
                        
                        completionOption = .dismissAndForwardAction
                        
                        viewController?.addSystemEvent(name: WEX_RATING_SUBMITTED_EVENT_NAME,
                                                      systemData: systemData,
                                                      applicationData: ["we_wk_rating": selectedCount])
                    }
                } else {
                    // Here UI may be updated to prompt choosing a rating value.
                }
            }
            
            completion(completionOption)
        }
    }
}

