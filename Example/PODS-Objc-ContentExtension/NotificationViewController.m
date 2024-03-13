//
//  NotificationViewController.m
//  PODS-Objc-ContentExtension
//
//  Created by Bhavesh Sarwar on 13/03/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import <WEContentExtension/WEContentExtension-Swift.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;
@property WEXRichPushNotificationViewController *weRichPushVC;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    if (_weRichPushVC == NULL){
        _weRichPushVC = [[WEXRichPushNotificationViewController alloc]init];
    }
    [_weRichPushVC setUpViewsWithParentVC:self];
    [super viewDidLoad];
    
}

- (void)didReceiveNotification:(UNNotification *)notification {
    [_weRichPushVC didReceiveNotification:notification];
}

- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion{
    [_weRichPushVC didReceiveNotificationResponse:response completionHandler:completion];
}

@end
