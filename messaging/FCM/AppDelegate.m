//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AppDelegate.h"
@import Firebase;
@import FirebaseInstanceID;
@import FirebaseMessaging;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Register for remote notifications
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
    // iOS 7.1 or earlier
    UIRemoteNotificationType allNotificationTypes =
    (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge);
    [application registerForRemoteNotificationTypes:allNotificationTypes];
  } else {
    // iOS 8 or later
    // [END_EXCLUDE]
    UIUserNotificationType allNotificationTypes =
    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }

  // [START configure_firebase]
  [FIRApp configure];
  // [END configure_firebase]

  // Add observer for InstanceID token refresh callback.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                               name:kFIRInstanceIDTokenRefreshNotification object:nil];
  return YES;
}

// [START receive_message]
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.
  // TODO: Handle data of notification

  // Print message ID.
  NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);

  // Pring full message.
  NSLog(@"%@", userInfo);
}
// [END receive_message]

// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
  // Note that this callback will be fired everytime a new token is generated, including the first
  // time. So if you need to retrieve the token as soon as it is available this is where that
  // should be done.
  NSString *refreshedToken = [[FIRInstanceID instanceID] token];
  NSLog(@"InstanceID token: %@", refreshedToken);

  // Connect to FCM since connection may have failed when attempted before having a token.
  [self connectToFcm];

  // TODO: If necessary send token to appliation server.
}
// [END refresh_token]

// [START connect_to_fcm]
- (void)connectToFcm {
  [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
    if (error != nil) {
      NSLog(@"Unable to connect to FCM. %@", error);
    } else {
      NSLog(@"Connected to FCM.");
    }
  }];
}
// [END connect_to_fcm]

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [self connectToFcm];
}

// [START disconnect_from_fcm]
- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[FIRMessaging messaging] disconnect];
  NSLog(@"Disconnected from FCM");
}
// [END disconnect_from_fcm]

@end
