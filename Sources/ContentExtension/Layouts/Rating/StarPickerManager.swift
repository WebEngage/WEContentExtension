//
//  StarPickerManager.swift
//
//
//  Created by Shubham Naidu on 05/11/23.
//

import Foundation
import UserNotifications
import UIKit

@available(iOS 10.0, *)
class StarPickerManager: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    var notification: UNNotification?
    var starRatingRows: [String]?

    init(notification: UNNotification) {
        super.init()

        if let source = notification.request.content.userInfo["source"] as? String, source == "webengage" {
            self.notification = notification

            if let expandableDetails = notification.request.content.userInfo["expandableDetails"] as? [String: Any],let noOfStars = expandableDetails["ratingScale"] as? Int{
                let selectedStar = "⭐"
                let unselectedStar = "☆"

                var pickerData = [String]()

                for i in 1...noOfStars {
                    var starRowString = ""
                    for _ in 1...i {
                        starRowString += selectedStar
                    }

                    for _ in i + 0...noOfStars {
                        starRowString += unselectedStar
                    }

                    pickerData.append(starRowString)
                }

                self.starRatingRows = pickerData
            }
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return starRatingRows?.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0 // This may depend on various factors such as font, which might be derived from notification data
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return starRatingRows?[row]
    }
}
