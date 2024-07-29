//
//  File.swift
//  
//
//  Created by Shubham Naidu on 13/11/23.
//

import Foundation
import UIKit

extension WEXCarouselPushNotificationViewController{
    
    func downloadRemaining(from downloadFromIndex: Int) {
        for i in downloadFromIndex..<carouselItems.count {
            DispatchQueue.global(qos: .userInitiated).async {
                if let carouselItem = self.carouselItems[0] as? [String: Any] ,let imageURL = carouselItem[WEConstants.IMAGE] as? String,
                   let imageUrl = URL(string: imageURL),
                   let imageData = try? Data(contentsOf: imageUrl),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.images[i] = image
                        self.wasLoaded[i] = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.images[i] = self.getErrorImage()!
                        self.wasLoaded[i] = false
                    }
                }
            }
        }
    }
    
    func getActivityDictionaryForCurrentNotification() -> [String: Any]? {
        if let viewController = self.viewController {
            return viewController.getActivityDictionaryForCurrentNotification() as? [String : Any]
        }
        return nil
    }
    
    func writeObject(_ object: Any, withKey key: String) {
        if let viewController = self.viewController {
            viewController.updateActivity(object: object, forKey: key)
        }
    }
    
    func getLoadingImage() -> UIImage? {
        if self.loadingImage == nil {
            let size = getImageFrameSize()
            let width = size.width
            let height = size.height
            let center = CGPoint(x: width / 2.0, y: height / 2.0)
            let holeWidth: CGFloat = 16.0
            let topBottomBarExtra: CGFloat = 10.0
            let margins: CGFloat = 20.0
            
            UIGraphicsBeginImageContext(size)
            self.loadingImage?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            if let context = UIGraphicsGetCurrentContext() {
                context.setLineCap(.round)
                context.setLineWidth(10.0)
                //                context.setRGBStrokeColor(0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).setStroke()
                context.setBlendMode(.normal)
                
                // Top Bar
                context.move(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0 - topBottomBarExtra, y: margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0 + topBottomBarExtra, y: margins))
                
                // Left Part
                context.move(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: margins))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: (height - 2 * margins) / 3.0 + margins))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0, y: center.y))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: center.y + (height - 2 * margins) / 6.0))
                context.addLine(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0, y: height - margins))
                
                // Right Part
                context.move(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: (height - 2 * margins) / 3.0 + margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0, y: center.y))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: center.y + (height - 2 * margins) / 6.0))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0, y: height - margins))
                
                // BottomBar
                context.move(to: CGPoint(x: center.x - holeWidth / 2.0 - (height - 2 * margins) / 6.0 - topBottomBarExtra, y: height - margins))
                context.addLine(to: CGPoint(x: center.x + holeWidth / 2.0 + (height - 2 * margins) / 6.0 + topBottomBarExtra, y: height - margins))
                
                context.strokePath()
                self.loadingImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                UIGraphicsBeginImageContext(size)
                self.loadingImage?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
                context.setLineCap(.round)
                context.setLineWidth(5.0)
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).setStroke()
                context.setBlendMode(.normal)
                
                let dx: CGFloat = 8.0
                let dy: CGFloat = 8.0
                
                for i in 1...4 {
                    let mid = (i + 1) / 2
                    var x: CGFloat
                    let yTop = center.y - CGFloat(i) * dy
                    let yBottom = center.y + CGFloat(i) * dy
                    
                    for j in 1...i {
                        if i % 2 == 0 {
                            x = center.x - (CGFloat(mid - j) * dx + dx / 2.0)
                        } else {
                            x = center.x - CGFloat(mid - j) * dx
                        }
                        
                        context.move(to: CGPoint(x: x, y: yTop))
                        context.addLine(to: CGPoint(x: x, y: yTop))
                        context.move(to: CGPoint(x: x, y: yBottom))
                        context.addLine(to: CGPoint(x: x, y: yBottom))
                    }
                }
                
                context.strokePath()
                self.loadingImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
        return self.loadingImage
    }
    
    func getErrorImage() -> UIImage? {
        let size = getImageFrameSize()
        
        if self.errorImage == nil {
            let width = size.width
            let height = size.height
            let startPoint = CGPoint(x: width / 2.0, y: height / 4.0)
            let rightPoint = CGPoint(x: width / 2.0 + height / 3.464, y: 0.75 * height)
            let leftPoint = CGPoint(x: width / 2.0 - height / 3.464, y: 0.75 * height)
            
            UIGraphicsBeginImageContext(size)
            self.errorImage?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            
            if let context = UIGraphicsGetCurrentContext() {
                context.setLineCap(.round)
                context.setLineWidth(10.0)
                //                context.setRGBStrokeColor(0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).setStroke()
                context.setBlendMode(.normal)
                
                context.move(to: startPoint)
                context.addLine(to: leftPoint)
                context.addLine(to: rightPoint)
                context.addLine(to: startPoint)
                
                context.move(to: CGPoint(x: startPoint.x, y: startPoint.y + 40))
                context.addLine(to: CGPoint(x: startPoint.x, y: rightPoint.y - 40))
                
                context.move(to: CGPoint(x: startPoint.x, y: rightPoint.y - 20))
                context.addLine(to: CGPoint(x: startPoint.x, y: rightPoint.y - 20))
                
                context.strokePath()
                self.errorImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
        return self.errorImage
    }
    
    func addViewEventForIndex(_ index: Int) {
        addViewEventForIndex(index, isFirst: false)
    }
    
    func addViewEventForIndex(_ index: Int, isFirst first: Bool) {
        if let userInfo = notification?.request.content.userInfo,
           let expandableDetails = userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
           let items = expandableDetails[WEConstants.ITEMS] as? [[String: Any]],
           items.count > index,
           let expId = userInfo[WEConstants.EXPERIMENT_ID] as? String,
           let notifId = userInfo[WEConstants.NOTIFICATION_ID] as? String {
            
            let callToAction = items[index]["id"] as? String ?? ""
            let ctaIdPrev = first ? "UNKNOWN" : items[(index + items.count - 1) % items.count]["id"] as? String ?? ""
            
            if let viewController = self.viewController {
                viewController.addSystemEvent(name: WEX_EVENT_NAME_PUSH_NOTIFICATION_ITEM_VIEW, systemData: [
                    "id": notifId,
                    WEConstants.EXPERIMENT_ID: expId,
                    "call_to_action": callToAction,
                    "navigated_from": ctaIdPrev
                ], applicationData: [:])
            }
        }
    }
    
    func setCTAForIndex(_ index: Int) {
        let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any]
        let items = expandableDetails?[WEConstants.ITEMS] as? [Any]
        if let currentItem = items?[index] as? [String: Any] {
            let ctaId = currentItem["id"] as? String ?? ""
            let actionLink = currentItem[WEConstants.ACTION_LINK] as? String ?? ""
            self.viewController?.setCTAWithId(ctaId, andLink: actionLink)
        }
    }
}
