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

// [START import]
#import <Firebase/Core.h>
#import <GINDeepLink/GINDeepLink.h>
// [END import]

@implementation AppDelegate

// [START didfinishlaunching]
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Use Firebase library to configure APIs
  NSError *configureError;
  BOOL status = [[FIRContext sharedInstance] configure:&configureError];
  NSAssert(status, @"Error configuring Firebase services: %@", configureError);

  // Override point for customization after application launch.
  [GINDeepLink setClientID:[FIRContext sharedInstance].serviceInfo.clientID];
  [GINDeepLink setAPIKey:[FIRContext sharedInstance].serviceInfo.apiKey];
  [GINDeepLink setURLScheme:@"ddlurl"];
  [GINDeepLink applicationDidFinishLaunchingWithOptions:launchOptions];
  return YES;
}
// [END didfinishlaunching]

// [START openurl]
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  GINReceivedInvite *invite =
      [GINDeepLink handleURL:url sourceApplication:sourceApplication annotation:annotation];
  if (invite.deepLink) {
    // [START_EXCLUDE]
    NSString *matchType =
        (invite.matchType == kGINReceivedInviteMatchTypeWeak) ? @"Weak" : @"Strong";
    NSString *message =
        [NSString stringWithFormat:@"Deep link from: %@\nDeep Link: %@\nMatch Type: %@\n",
                                   sourceApplication, invite.deepLink, matchType];
    [self showDeepLinkAlertViewWithMessage:message];
    // [END_EXCLUDE]
    return YES;
  }
  return NO;
}
// [END openurl]

// [START continueuseractivity]
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *))restorationHandler {
  // [START_EXCLUDE silent]
  // Show the deep link URL from userActivity.
  NSString *message =
      [NSString stringWithFormat:@"continueUserActivity webPageURL:\n%@", userActivity.webpageURL];
  [self showDeepLinkAlertViewWithMessage:message];
  // [END_EXCLUDE]
  GINReceivedInvite *invite =
      [GINDeepLink continueUserActivity:userActivity restorationHandler:restorationHandler];
  if (invite.deepLink) {
    [self application:application
                  openURL:[NSURL URLWithString:invite.deepLink]
        sourceApplication:@"com.apple.mobilesafari"
               annotation:@{}];
    return YES;
  }
  return NO;
}
// [END continueuseractivity]

- (void)showDeepLinkAlertViewWithMessage:(NSString *)message {
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                     NSLog(@"OK");
                                                   }];

  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:@"Deep-link Data"
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:okAction];
  [self.window.rootViewController presentViewController:alertController
                                               animated:YES
                                             completion:nil];
}

@end
