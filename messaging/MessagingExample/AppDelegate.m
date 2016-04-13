//
//  Copyright (c) 2015 Google Inc.
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
@import FirebaseAnalytics;
@import FirebaseMessaging;
@import FirebaseInstanceID;

@interface AppDelegate ()
@property(nonatomic, strong) void (^registrationHandler)
    (NSString *registrationToken, NSError *error);
@property(nonatomic, assign) BOOL connectedToFCM;
@property(nonatomic, strong) NSString *registrationToken;
@property(nonatomic, assign) BOOL subscribedToTopic;
@end

NSString *const SubscriptionTopic = @"/topics/global";

@implementation AppDelegate

// [START register_for_remote_notifications]
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // [START_EXCLUDE]
  self.registrationKey = @"onRegistrationCompleted";
  self.messageKey = @"onMessageReceived";
  // Configure the Firebase context: parses the GoogleService-Info.plist, and initializes
  // the services that have entries in the file
  [FIRApp configure];

  self.fcmSenderID = [FIRApp defaultApp].options.GCMSenderID;
  // Register for remote notifications
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
    // iOS 7.1 or earlier
    UIRemoteNotificationType allNotificationTypes =
        (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeBadge);
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
  // [END register_for_remote_notifications]
  __weak typeof(self) weakSelf = self;
  // Handler for registration token request
  _registrationHandler = ^(NSString *registrationToken, NSError *error) {
    if (registrationToken != nil) {
      weakSelf.registrationToken = registrationToken;
      NSLog(@"Registration Token: %@", registrationToken);
      [weakSelf subscribeToTopic];
      NSDictionary *userInfo = @{ @"registrationToken" : registrationToken };
      [[NSNotificationCenter defaultCenter] postNotificationName:weakSelf.registrationKey
                                                          object:nil
                                                        userInfo:userInfo];
    } else {
      NSLog(@"Registration to GCM failed with error: %@", error.localizedDescription);
      NSDictionary *userInfo = @{ @"error" : error.localizedDescription };
      [[NSNotificationCenter defaultCenter] postNotificationName:weakSelf.registrationKey
                                                          object:nil
                                                        userInfo:userInfo];
    }
  };
  return YES;
}

- (void)subscribeToTopic {

  // If the app has a registration token and is connected to GCM, proceed to subscribe to the
  // topic
  if (_registrationToken && _connectedToFCM) {
    [[FIRMessaging messaging] subscribeToTopic:SubscriptionTopic];
    self.subscribedToTopic = YES;
    NSLog(@"Subscribed to %@", SubscriptionTopic);
  }
}

// [START connect_gcm_service]
- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Connect to the GCM server to receive non-APNS notifications
  [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"Could not connect to FCM: %@", error.localizedDescription);
      return;
    }
    self.connectedToFCM = true;
    NSLog(@"Connected to GCM");
    // [START_EXCLUDE]
    [self subscribeToTopic];
    // [END_EXCLUDE]
  }];
}
// [END connect_gcm_service]

// [START disconnect_gcm_service]
- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[FIRMessaging messaging] disconnect];
  // [START_EXCLUDE]
  self.connectedToFCM = NO;
  // [END_EXCLUDE]
}
// [END disconnect_gcm_service]

// [START receive_apns_token]
- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // [END receive_apns_token]
  // [START get_gcm_reg_token]
  // Start the GGLInstanceID shared instance with the that config and request a registration
  // token to enable reception of notifications

  [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeSandbox];
  [[FIRInstanceID instanceID] tokenWithAuthorizedEntity:_fcmSenderID
                                                  scope:kFIRInstanceIDScopeFirebaseMessaging
                                                options:nil
                                                handler:_registrationHandler];
  // [END get_gcm_reg_token]
}

// [START receive_apns_token_error]
- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"Registration for remote notification failed with error: %@", error.localizedDescription);
  // [END receive_apns_token_error]
  NSDictionary *userInfo = @{ @"error" : error.localizedDescription };
  [[NSNotificationCenter defaultCenter] postNotificationName:_registrationKey
                                                      object:nil
                                                    userInfo:userInfo];
}

// [START ack_message_reception]
- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo {
  NSLog(@"Notification received: %@", userInfo);
  // This works only if the app started the GCM service
  [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
  // Handle the received message
  // [START_EXCLUDE]
  [[NSNotificationCenter defaultCenter] postNotificationName:_messageKey
                                                      object:nil
                                                    userInfo:userInfo];
  // [END_EXCLUDE]
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
  NSLog(@"Notification received: %@", userInfo);
  // This works only if the app started the GCM service
  [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
  // Handle the received message
  // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
  // [START_EXCLUDE]
  [[NSNotificationCenter defaultCenter] postNotificationName:_messageKey
                                                      object:nil
                                                    userInfo:userInfo];
  handler(UIBackgroundFetchResultNoData);
  // [END_EXCLUDE]
}
// [END ack_message_reception]

// [START on_token_refresh]
- (void)onTokenRefresh {
  // A rotation of the registration tokens is happening, so the app needs to request a new token.
  NSLog(@"The FCM registration token needs to be changed.");
  [[FIRInstanceID instanceID] tokenWithAuthorizedEntity:_fcmSenderID
                                                  scope:kFIRInstanceIDScopeFirebaseMessaging
                                                options:nil
                                                handler:_registrationHandler];
}
// [END on_token_refresh]

// [START upstream_callbacks]
- (void)willSendDataMessageWithID:(NSString *)messageID error:(NSError *)error {
  if (error) {
    // Failed to send the message.
  } else {
    // Will send message, you can save the messageID to track the message
  }
}

- (void)didSendDataMessageWithID:(NSString *)messageID {
  // Did successfully send message identified by messageID
}
// [END upstream_callbacks]

- (void)didDeleteMessagesOnServer {
  // Some messages sent to this device were deleted on the GCM server before reception, likely
  // because the TTL expired. The client should notify the app server of this, so that the app
  // server can resend those messages.
}

@end
