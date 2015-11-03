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

@interface AppDelegate ()
@property(nonatomic, strong) void (^registrationHandler)
(NSString *registrationToken, NSError *error);
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSError* configureError;
  BOOL status = [[FIRContext sharedInstance] configure:&configureError];
  if (status != YES) {
    // show an error.
    NSAssert(!configureError, @"Error configuring Firebase services: %@", configureError);
  }
  // Register for remote notifications
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
    // iOS 7.1 or earlier
    UIRemoteNotificationType allNotificationTypes =
    (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge);
    [application registerForRemoteNotificationTypes:allNotificationTypes];
  } else {
    // iOS 8 or later
    UIUserNotificationType allNotificationTypes =
    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }
  GCMConfig *gcmConfig = [GCMConfig defaultConfig];
  gcmConfig.receiverDelegate = self;
  [[GCMService sharedInstance] startWithConfig:gcmConfig];
  // Handler for registration token request
  _registrationHandler = ^(NSString *registrationToken, NSError *error){
    if (registrationToken != nil) {
      NSLog(@"Registration Token: %@", registrationToken);
    } else {
      NSLog(@"Registration to GCM failed with error: %@", error.localizedDescription);
    }
  };
  return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Connect to the GCM server to receive non-APNS notifications
  [[GCMService sharedInstance] connectWithHandler:^(NSError *error) {
    if (error) {
      NSLog(@"Could not connect to GCM: %@", error.localizedDescription);
    } else {
      NSLog(@"Connected to GCM");
    }
  }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[GCMService sharedInstance] disconnect];
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // Create a config and set a delegate that implements the GGLInstaceIDDelegate protocol.
  GGLInstanceIDConfig *instanceIDConfig = [GGLInstanceIDConfig defaultConfig];
  // Start the GGLInstanceID shared instance with the that config and request a registration
  // token to enable reception of notifications
  [[GGLInstanceID sharedInstance] startWithConfig:instanceIDConfig];
  NSDictionary *registrationOptions = @{kGGLInstanceIDRegisterAPNSOption:deviceToken,
                           kGGLInstanceIDAPNSServerTypeSandboxOption:@YES};
  NSLog(@"Sender Id: %@", [FIRContext sharedInstance].gcmSenderID);
  [[GGLInstanceID sharedInstance] tokenWithAuthorizedEntity:[FIRContext sharedInstance].gcmSenderID
                                                      scope:kGGLInstanceIDScopeGCM
                                                    options:registrationOptions
                                                    handler:_registrationHandler];
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"Registration for remote notification failed with error: %@", error.localizedDescription);
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
  NSLog(@"Notification received: %@", userInfo);
  // This works only if the app started the GCM service
  [[GCMService sharedInstance] appDidReceiveMessage:userInfo];
  // Handle the received message
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
  NSLog(@"Notification received: %@", userInfo);
  // This works only if the app started the GCM service
  [[GCMService sharedInstance] appDidReceiveMessage:userInfo];
  // Handle the received message
  // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
  handler(UIBackgroundFetchResultNoData);
}


@end
