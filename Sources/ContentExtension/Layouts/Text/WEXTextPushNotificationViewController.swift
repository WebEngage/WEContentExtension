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
    let CONTENT_PADDING = 10.0
    let TITLE_BODY_SPACE = 5
    let LANDSCAPE_ASPECT = 0.5

    override func didReceiveNotification(_ notification: UNNotification) {
        if let source = notification.request.content.userInfo["source"] as? String, source == "webengage" {
            self.notification = notification
            initialiseViewHierarchy()
        }
    }

    override func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if let source = response.notification.request.content.userInfo["source"] as? String, source == "webengage" {
            completion(.dismissAndForwardAction)
        }
    }

    func initialiseViewHierarchy() {
        if #available(iOS 13.0, *) {
            view?.backgroundColor = UIColor.WEXWhiteColor()
        }
        let superViewWrapper = UIView()
        view?.addSubview(superViewWrapper)
        setupLabelsContainer()
    }

    func setupLabelsContainer() {
        if let superViewWrapper = view?.subviews.first,
            let expandableDetails = notification?.request.content.userInfo["expandableDetails"] as? [String: Any], let colorHex = expandableDetails["bckColor"] as? String{
            let richContentView = UIView()
            if #available(iOS 13.0, *) {
                richContentView.backgroundColor = UIColor.colorFromHexString(colorHex, defaultColor: UIColor.WEXWhiteColor())
            }

            if let expandedDetails = notification?.request.content.userInfo["expandableDetails"] as? [String: Any]{
                let title = expandedDetails["rt"] as? String
                let subtitle = expandedDetails["rst"] as? String
                let message = expandedDetails["rm"] as? String
                var titlePresent = title != ""
                var subTitlePresent = subtitle != ""
                var messagePresent = message != ""

                if !titlePresent {
                    titlePresent = notification?.request.content.title != ""
                }
                if !subTitlePresent {
                    subTitlePresent = notification?.request.content.subtitle != ""
                }
                if !messagePresent {
                    messagePresent = notification?.request.content.body != ""
                }
                let richTitleLabel = UILabel()
                if let viewController = viewController, let title = title {
                    richTitleLabel.attributedText = viewController.getHtmlParsedString(title, isTitle: true, bckColor: colorHex)
                    richTitleLabel.textAlignment = viewController.naturalTextAligmentForText(richTitleLabel.text)
                }

                let richSubLabel = UILabel()
                if let viewController = viewController, let subtitle = subtitle {
                    richSubLabel.attributedText = viewController.getHtmlParsedString(subtitle, isTitle: true, bckColor: colorHex)
                    richSubLabel.textAlignment = viewController.naturalTextAligmentForText(richSubLabel.text)
                }

                let richBodyLabel = UILabel()
                if let viewController = viewController, let message = message {
                    richBodyLabel.attributedText = viewController.getHtmlParsedString(message, isTitle: false, bckColor: colorHex)
                    richBodyLabel.textAlignment = viewController.naturalTextAligmentForText(richBodyLabel.text)
                }
                richBodyLabel.numberOfLines = 0


                richContentView.addSubview(richTitleLabel)
                richContentView.addSubview(richSubLabel)
                richContentView.addSubview(richBodyLabel)

                superViewWrapper.addSubview(richContentView)
                setupConstraints()
            }
        }
    }

    func setupConstraints() {
        if let view = view, let superViewWrapper = view.subviews.first,
           let richContentView = superViewWrapper.subviews.first, let viewController = viewController {
            
                superViewWrapper.translatesAutoresizingMaskIntoConstraints = false
                superViewWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                superViewWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
                superViewWrapper.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                superViewWrapper.bottomAnchor.constraint(equalTo: richContentView.bottomAnchor).isActive = true

                viewController.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: superViewWrapper.bottomAnchor).isActive = true

                richContentView.translatesAutoresizingMaskIntoConstraints = false
                richContentView.leadingAnchor.constraint(equalTo: superViewWrapper.leadingAnchor).isActive = true
                richContentView.trailingAnchor.constraint(equalTo: superViewWrapper.trailingAnchor).isActive = true
                richContentView.topAnchor.constraint(equalTo: superViewWrapper.topAnchor).isActive = true

                // Rich View labels
                 let richTitleLabel = richContentView.subviews[0] as UIView
                   let richSubTitleLabel = richContentView.subviews[1] as UIView
                   let richBodyLabel = richContentView.subviews[2] as UIView
                    
                    richTitleLabel.translatesAutoresizingMaskIntoConstraints = false
                    richTitleLabel.leadingAnchor.constraint(equalTo: richContentView.leadingAnchor, constant: CONTENT_PADDING).isActive = true
                    richTitleLabel.trailingAnchor.constraint(equalTo: richContentView.trailingAnchor, constant: -CONTENT_PADDING).isActive = true
                    richTitleLabel.topAnchor.constraint(equalTo: richContentView.topAnchor, constant: CONTENT_PADDING).isActive = true

                    richSubTitleLabel.translatesAutoresizingMaskIntoConstraints = false
                    richSubTitleLabel.leadingAnchor.constraint(equalTo: richContentView.leadingAnchor, constant: CONTENT_PADDING).isActive = true
                    richSubTitleLabel.trailingAnchor.constraint(equalTo: richContentView.trailingAnchor, constant: -CONTENT_PADDING).isActive = true
                    richSubTitleLabel.topAnchor.constraint(equalTo: richTitleLabel.bottomAnchor, constant: 0).isActive = true

                    richBodyLabel.translatesAutoresizingMaskIntoConstraints = false
                    richBodyLabel.leadingAnchor.constraint(equalTo: richContentView.leadingAnchor, constant: CONTENT_PADDING).isActive = true
                    richBodyLabel.trailingAnchor.constraint(equalTo: richContentView.trailingAnchor, constant: -CONTENT_PADDING).isActive = true
                    richBodyLabel.topAnchor.constraint(equalTo: richSubTitleLabel.bottomAnchor, constant: 0).isActive = true
                    richBodyLabel.bottomAnchor.constraint(equalTo: richContentView.bottomAnchor, constant: -CONTENT_PADDING).isActive = true
        }
    }
}
