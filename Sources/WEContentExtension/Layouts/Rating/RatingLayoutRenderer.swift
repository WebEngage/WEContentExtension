//
//  File.swift
//  
//
//  Created by Shubham Naidu on 13/11/23.
//

import Foundation
import UIKit

extension WEXRatingPushNotificationViewController{
    
    /// Initializes the view hierarchy for displaying a notification with rich content and optional banner image.
    func initialiseViewHierarchy() {
        if #available(iOS 13.0, *) {
            self.view?.backgroundColor = UIColor.WEXWhiteColor()
        }

        let superViewWrapper = UIView()
        self.view?.addSubview(superViewWrapper)

        let mainContentView = UIView()
        superViewWrapper.addSubview(mainContentView)

        let expandableDetails = self.notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any]

        var backgroundImage = false

        if ((expandableDetails?[WEConstants.IMAGE] as? String) != nil),
           let attachments = self.notification?.request.content.attachments,
           attachments.count > 0 {
                if let attachment = attachments.first,
                   attachment.url.startAccessingSecurityScopedResource() {
                    if let imageData = try? Data(contentsOf: attachment.url),
                       let image = UIImage.animatedImageWithAnimatedGIF(data: imageData){
                        backgroundImage = true
                        let imageView = UIImageView()
                        imageView.image = image
                        imageView.contentMode = .scaleAspectFill
                        mainContentView.addSubview(imageView)
                    }
                    attachment.url.stopAccessingSecurityScopedResource()
                }
            }

        var title: String?, message: String?, textColor: String?, bckColor: String?

        if let content = expandableDetails?["content"] as? [String: String] {
            title = content["title"]
            message = content["message"]
            textColor = content["textColor"]
            bckColor = content["bckColor"]
        }

        let textDisplayView = UIView()

        if backgroundImage {
            textDisplayView.isOpaque = false
            textDisplayView.backgroundColor = .clear
        } else {
            if let bckColor = bckColor {
                if #available(iOS 13.0, *) {
                    textDisplayView.backgroundColor = UIColor.colorFromHexString(bckColor, defaultColor: .WEXLightTextColor())
                }
            } else {
                if #available(iOS 13.0, *) {
                    textDisplayView.backgroundColor = .WEXLightTextColor()
                }
            }
        }

        var titleLabel: UILabel?
        let contentTitlePresent = (title != nil) && (title != "")
        let contentMessagePresent = (message != nil) && (message != "")

        if !contentTitlePresent && !contentMessagePresent && !backgroundImage {
            title = self.notification?.request.content.title
            message = self.notification?.request.content.body
        }

        let titlePresent = (title != nil) && (title != "")
        let messagePresent = (message != nil) && (message != "")

        if titlePresent {
            titleLabel = UILabel()
            if let alignment = self.viewController?.naturalTextAlignmentForText(title){
                titleLabel?.textAlignment = alignment
            }
            titleLabel?.text = title
            titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)

            if let textColor = textColor {
                if #available(iOS 13.0, *) {
                    titleLabel?.textColor = UIColor.colorFromHexString(textColor, defaultColor: .WEXLabelColor())
                }
            } else {
                if #available(iOS 13.0, *) {
                    titleLabel?.textColor = .WEXLabelColor()
                }
            }

            textDisplayView.addSubview(titleLabel!)
        }

        if messagePresent {
            let messageLabel = UILabel()
            if let alignment = self.viewController?.naturalTextAlignmentForText(messageLabel.text, forDescription: true){
                messageLabel.textAlignment = alignment
            }
            messageLabel.text = message

            if let textColor = textColor {
                if #available(iOS 13.0, *) {
                    messageLabel.textColor = UIColor.colorFromHexString(textColor, defaultColor: .WEXLabelColor())
                }
            } else {
                if #available(iOS 13.0, *) {
                    messageLabel.textColor = .WEXLabelColor()
                }
            }

            messageLabel.numberOfLines = 3

            textDisplayView.addSubview(messageLabel)
        }

        mainContentView.addSubview(textDisplayView)

        let contentSeparator = UIView()
        if #available(iOS 13.0, *) {
            contentSeparator.backgroundColor = .WEXGreyColor()
        }
        superViewWrapper.addSubview(contentSeparator)

        var richTitle = expandableDetails?[WEConstants.RICHTITLE] as? String
        var richSub = expandableDetails?[WEConstants.RICHSUBTITLE] as? String
        var richMessage = expandableDetails?[WEConstants.RICHMESSAGE] as? String

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

        let colorHex = expandableDetails?[WEConstants.BACKCOLOR] as? String

        // Add a notification content view for displaying title and body.
        let richContentView = UIView()
        if #available(iOS 13.0, *) {
            richContentView.backgroundColor = UIColor.colorFromHexString(colorHex ?? WEConstants.WHITECOLOR, defaultColor: .WEXWhiteColor())
        }

        let richTitleLabel = UILabel()
        if let richTitle = richTitle{
            richTitleLabel.attributedText = self.viewController?.getHtmlParsedString(richTitle, isTitle: true, bckColor: colorHex ?? WEConstants.WHITECOLOR)
            if let alignment = self.viewController?.naturalTextAlignmentForText(richTitleLabel.text){
                richTitleLabel.textAlignment = alignment
            }
        }
        let richSubLabel = UILabel()
        if let richSub = richSub {
            richSubLabel.attributedText = self.viewController?.getHtmlParsedString(richSub, isTitle: true, bckColor: colorHex ?? WEConstants.WHITECOLOR)
            if let alignment = self.viewController?.naturalTextAlignmentForText(richSubLabel.text){
                richSubLabel.textAlignment = alignment
            }
        }

        let richBodyLabel = UILabel()
        if let richMessage = richMessage{
            richBodyLabel.attributedText = WEXCoreUtils.getAttributedString(message: richMessage, colorHex: colorHex ?? WEConstants.WHITECOLOR , viewController: self.viewController)
            richBodyLabel.numberOfLines = 0
        }
        richContentView.addSubview(richTitleLabel)
        richContentView.addSubview(richSubLabel)
        richContentView.addSubview(richBodyLabel)

        superViewWrapper.addSubview(richContentView)

        let separator = UIView()
        if #available(iOS 13.0, *) {
            separator.backgroundColor = UIColor.colorFromHexString(colorHex ?? WEConstants.WHITECOLOR, defaultColor: .WEXGreyColor())
        }
        superViewWrapper.addSubview(separator)

        let starRatingView = UIView()
        if #available(iOS 13.0, *) {
            starRatingView.backgroundColor = UIColor.colorFromHexString(colorHex ?? WEConstants.WHITECOLOR, defaultColor: .WEXWhiteColor())
        }

        self.labelsWrapper = UIView()
        self.unselectedLabel = UILabel()
        self.selectedLabel = UILabel()
        if let unselectedLabel = self.unselectedLabel {
            self.labelsWrapper?.addSubview(unselectedLabel)
        }

        if let selectedLabel = self.selectedLabel {
            self.labelsWrapper?.addSubview(selectedLabel)
        }
        
        starRatingView.addSubview(labelsWrapper ?? UIView())
        superViewWrapper.addSubview(starRatingView)

        self.setUpConstraintsWithImageView(imageViewIncluded: backgroundImage, titlePresent: titlePresent, messagePresent: messagePresent)

        self.renderStarControl()
    }
    
    func renderStarControl() {
        let selectedCount = self.selectedCount
        if let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String : Any], let totalCount =  expandableDetails[WEConstants.RATING_SCALE] as? Int {
            self.selectedLabel?.textAlignment = NSTextAlignment.natural
            
            let starChar: Character = "\u{2605}"
            let starString = String(starChar)
            
            var spaceAppendString = " "
            if totalCount <= 5 {
                spaceAppendString = "  "
            }
            
            var starStringSelected = ""
            
            for i in 0..<selectedCount {
                starStringSelected += starString
                if i < totalCount {
                    starStringSelected += spaceAppendString
                }
            }
            
            self.selectedLabel?.text = starStringSelected
            self.selectedLabel?.textColor = UIColor.orange
            self.selectedLabel?.font = self.selectedLabel?.font.withSize(STAR_FONT_SIZE)
            
            self.unselectedLabel?.textAlignment = NSTextAlignment.left
            
            var starStringUnselected = ""
            
            for i in ((selectedCount)..<totalCount) {
                starStringUnselected += starString
                if i < totalCount {
                    starStringUnselected += spaceAppendString
                }
            }
            
            self.unselectedLabel?.text = starStringUnselected
            if #available(iOS 13.0, *) {
                self.unselectedLabel?.textColor = UIColor.WEXGreyColor()
            }
            self.unselectedLabel?.font = self.unselectedLabel?.font.withSize(STAR_FONT_SIZE)
        }
    }
    
    func setUpConstraintsWithImageView(imageViewIncluded: Bool, titlePresent: Bool, messagePresent: Bool) {
        if let view = self.view{
            let superViewWrapper = view.subviews[0]
            let mainContentView = superViewWrapper.subviews[0]
            let contentSeparator = superViewWrapper.subviews[1]
            let richContentView = superViewWrapper.subviews[2]
            let separator = superViewWrapper.subviews[3]
            let starRatingWrapper = superViewWrapper.subviews[4]
            
            superViewWrapper.translatesAutoresizingMaskIntoConstraints = false
            superViewWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            superViewWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            superViewWrapper.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            superViewWrapper.bottomAnchor.constraint(equalTo: starRatingWrapper.bottomAnchor).isActive = true
            
            // Top-level view constraints
            mainContentView.translatesAutoresizingMaskIntoConstraints = false
            mainContentView.leadingAnchor.constraint(equalTo: mainContentView.superview!.leadingAnchor).isActive = true
            mainContentView.trailingAnchor.constraint(equalTo: mainContentView.superview!.trailingAnchor).isActive = true
            mainContentView.topAnchor.constraint(equalTo: mainContentView.superview!.topAnchor).isActive = true
            
            contentSeparator.translatesAutoresizingMaskIntoConstraints = false
            contentSeparator.leadingAnchor.constraint(equalTo: contentSeparator.superview!.leadingAnchor).isActive = true
            contentSeparator.trailingAnchor.constraint(equalTo: contentSeparator.superview!.trailingAnchor).isActive = true
            contentSeparator.topAnchor.constraint(equalTo: mainContentView.bottomAnchor).isActive = true
            contentSeparator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            
            richContentView.translatesAutoresizingMaskIntoConstraints = false
            richContentView.leadingAnchor.constraint(equalTo: richContentView.superview!.leadingAnchor).isActive = true
            richContentView.trailingAnchor.constraint(equalTo: richContentView.superview!.trailingAnchor).isActive = true
            richContentView.topAnchor.constraint(equalTo: contentSeparator.bottomAnchor).isActive = true
            
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.leadingAnchor.constraint(equalTo: separator.superview!.leadingAnchor).isActive = true
            separator.trailingAnchor.constraint(equalTo: separator.superview!.trailingAnchor).isActive = true
            separator.topAnchor.constraint(equalTo: richContentView.bottomAnchor).isActive = true
            separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            
            starRatingWrapper.translatesAutoresizingMaskIntoConstraints = false
            starRatingWrapper.leadingAnchor.constraint(equalTo: starRatingWrapper.superview!.leadingAnchor).isActive = true
            starRatingWrapper.trailingAnchor.constraint(equalTo: starRatingWrapper.superview!.trailingAnchor).isActive = true
            starRatingWrapper.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
            starRatingWrapper.heightAnchor.constraint(equalToConstant: STAR_BAR_HEIGHT).isActive = true
            
            self.viewController?.view.bottomAnchor.constraint(equalTo: superViewWrapper.bottomAnchor).isActive = true
            
            // Main Content View Internal Constraints
            var textDisplaySubviewIndex = 0
            if imageViewIncluded {
                let imageView = mainContentView.subviews[0] as! UIImageView
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.topAnchor.constraint(equalTo: mainContentView.topAnchor).isActive = true
                imageView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor).isActive = true
                imageView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor).isActive = true
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0/3.0).isActive = true
                mainContentView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
                textDisplaySubviewIndex = 1
            }
            
            let textDisplayView = mainContentView.subviews[textDisplaySubviewIndex]
            textDisplayView.translatesAutoresizingMaskIntoConstraints = false
            textDisplayView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor).isActive = true
            textDisplayView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor).isActive = true
            textDisplayView.topAnchor.constraint(equalTo: mainContentView.topAnchor).isActive = true
            
            if !imageViewIncluded {
                mainContentView.bottomAnchor.constraint(equalTo: textDisplayView.bottomAnchor).isActive = true
            }
            
            // TextDisplayView internal constraints
            var messageSubViewIndex = 0
            var titleLabel: UILabel?
            
            if titlePresent {
                messageSubViewIndex = 1
                titleLabel = textDisplayView.subviews.first as? UILabel
                titleLabel?.translatesAutoresizingMaskIntoConstraints = false
                titleLabel?.leadingAnchor.constraint(equalTo: textDisplayView.leadingAnchor, constant: TEXT_PADDING).isActive = true
                titleLabel?.trailingAnchor.constraint(equalTo: textDisplayView.trailingAnchor, constant: 0 - TEXT_PADDING).isActive = true
                titleLabel?.topAnchor.constraint(equalTo: textDisplayView.topAnchor, constant: TEXT_PADDING).isActive = true
                
                if !messagePresent {
                    titleLabel?.bottomAnchor.constraint(equalTo: textDisplayView.bottomAnchor, constant: 0 - TEXT_PADDING).isActive = true
                }
            }
            
            if messagePresent {
                if messageSubViewIndex < textDisplayView.subviews.count,
                   let messageLabel = textDisplayView.subviews[messageSubViewIndex] as? UILabel{
                    messageLabel.translatesAutoresizingMaskIntoConstraints = false
                    messageLabel.leadingAnchor.constraint(equalTo: textDisplayView.leadingAnchor, constant: TEXT_PADDING).isActive = true
                    messageLabel.trailingAnchor.constraint(equalTo: textDisplayView.trailingAnchor, constant: 0 - TEXT_PADDING).isActive = true
                    
                    if titlePresent {
                        messageLabel.topAnchor.constraint(equalTo: titleLabel!.bottomAnchor, constant: TEXT_PADDING).isActive = true
                    } else {
                        messageLabel.topAnchor.constraint(equalTo: textDisplayView.topAnchor, constant: TEXT_PADDING).isActive = true
                    }
                    
                    messageLabel.bottomAnchor.constraint(equalTo: textDisplayView.bottomAnchor, constant: 0 - TEXT_PADDING).isActive = true
                }
            }
            // Rich View labels
            let richTitleLabel = richContentView.subviews[0]
            let richSubTitleLabel = richContentView.subviews[1]
            let richBodyLabel = richContentView.subviews[2]
            
            richTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            richTitleLabel.leadingAnchor.constraint(equalTo: richContentView.leadingAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
            richTitleLabel.trailingAnchor.constraint(equalTo: richContentView.trailingAnchor, constant: 0 - WEConstants.CONTENT_PADDING).isActive = true
            richTitleLabel.topAnchor.constraint(equalTo: richContentView.topAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
            
            richSubTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            richSubTitleLabel.leadingAnchor.constraint(equalTo: richContentView.leadingAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
            richSubTitleLabel.trailingAnchor.constraint(equalTo: richContentView.trailingAnchor, constant: 0 - WEConstants.CONTENT_PADDING).isActive = true
            richSubTitleLabel.topAnchor.constraint(equalTo: richTitleLabel.bottomAnchor, constant: 0).isActive = true
            
            richBodyLabel.translatesAutoresizingMaskIntoConstraints = false
            richBodyLabel.leadingAnchor.constraint(equalTo: richContentView.leadingAnchor, constant: WEConstants.CONTENT_PADDING).isActive = true
            richBodyLabel.trailingAnchor.constraint(equalTo: richContentView.trailingAnchor, constant: 0 - WEConstants.CONTENT_PADDING).isActive = true
            richBodyLabel.topAnchor.constraint(equalTo: richSubTitleLabel.bottomAnchor, constant: 0).isActive = true
            richBodyLabel.bottomAnchor.constraint(equalTo: richContentView.bottomAnchor, constant: -WEConstants.CONTENT_PADDING).isActive = true
            
            // Star rating view internal constraints
            if let labelsWrapper = self.labelsWrapper, let superview = labelsWrapper.superview, let selectedLabel = self.selectedLabel, let unselectedLabel = self.unselectedLabel{
                labelsWrapper.translatesAutoresizingMaskIntoConstraints = false
                labelsWrapper.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                labelsWrapper.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
                labelsWrapper.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
                
                
                selectedLabel.translatesAutoresizingMaskIntoConstraints = false
                selectedLabel.topAnchor.constraint(equalTo: labelsWrapper.topAnchor).isActive = true
                selectedLabel.bottomAnchor.constraint(equalTo: labelsWrapper.bottomAnchor).isActive = true
                selectedLabel.leadingAnchor.constraint(equalTo: labelsWrapper.leadingAnchor).isActive = true
                
                unselectedLabel.translatesAutoresizingMaskIntoConstraints = false
                unselectedLabel.topAnchor.constraint(equalTo: labelsWrapper.topAnchor).isActive = true
                unselectedLabel.bottomAnchor.constraint(equalTo: labelsWrapper.bottomAnchor).isActive = true
                unselectedLabel.trailingAnchor.constraint(equalTo: labelsWrapper.trailingAnchor).isActive = true
                unselectedLabel.leadingAnchor.constraint(equalTo: selectedLabel.trailingAnchor).isActive = true
            }
        }
    }
    
    @objc func doneButtonClicked(_ sender: Any) {
        let rowIndex = self.pickerView?.selectedRow(inComponent: 0) ?? 0
        
        selectedCount = rowIndex + 1
        renderStarControl()
        viewController?.resignFirstResponder()
    }
}

