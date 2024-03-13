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
class WEXRatingPushNotificationViewController: WEXRichPushLayout {
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
   
    @objc func canBecomeFirstResponder() -> Bool {
        return true
    }

    @objc func inputAccessoryView() -> UIView? {
        let frame = CGRect(x: 0, y: 0, width: CGFloat(self.view?.frame.size.width ?? 0), height: 50)
        
        let inputAccessoryView = UIView(frame: frame)
        if #available(iOS 13.0, *) {
            inputAccessoryView.backgroundColor = UIColor.WEXLightTextColor()
        }
        
        let doneButton = UIButton(type: .system)
        let attrTitle = NSAttributedString(string: "Done", attributes: [
            NSAttributedString.Key.underlineStyle: [],
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20),
            NSAttributedString.Key.foregroundColor: UIColor.colorFromHexString("0077cc", defaultColor: UIColor.blue)
        ])
        
        doneButton.setAttributedTitle(attrTitle, for: .normal)
        
        inputAccessoryView.addSubview(doneButton)
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.trailingAnchor.constraint(equalTo: inputAccessoryView.trailingAnchor, constant: -10.0).isActive = true
        doneButton.topAnchor.constraint(equalTo: inputAccessoryView.topAnchor).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: inputAccessoryView.bottomAnchor).isActive = true
        doneButton.addTarget(self, action: #selector(doneButtonClicked(_:)), for: .touchDown)
        
        return inputAccessoryView
    }

    @objc func inputView() -> UIView? {
        return self.pickerView
    }

    override func didReceiveNotification(_ notification: UNNotification) {
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




