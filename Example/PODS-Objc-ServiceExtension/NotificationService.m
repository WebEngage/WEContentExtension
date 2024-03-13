//
//  NotificationService.m
//  PODS-Objc-ServiceExtension
//
//  Created by Bhavesh Sarwar on 13/03/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import "NotificationService.h"
#import "WEServiceExtension/WEServiceExtension-Swift.h"

@interface NotificationService ()

@property (nonatomic, strong) WEXPushNotificationService *serviceExtension;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    if (_serviceExtension == NULL){
        _serviceExtension = [[WEXPushNotificationService alloc]init];
    }
    [_serviceExtension didReceiveNotificationRequest:request
                                  withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    [_serviceExtension serviceExtensionTimeWillExpire];
}

@end
