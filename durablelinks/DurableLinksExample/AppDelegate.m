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

#import <Firebase/Core.h>
#import <GINDeepLink/GINDeepLink.h>

@implementation AppDelegate

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

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  GINReceivedInvite *invite = [GINDeepLink handleURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation];
  if (invite.deepLink) {
    NSString *matchType = (invite.matchType == kGINReceivedInviteMatchTypeWeak) ?
        @"Weak" : @"Strong";
    NSString *message = [NSString stringWithFormat:
                         @"Deep link from: %@\nDeep Link: %@\nMatch Type: %@\n",
                         sourceApplication, invite.deepLink, matchType];
    [self showDeepLinkAlertViewWithMessage:message];
    return YES;
  }
  // Show the deep link that the app was called with.
  [self showDeepLinkAlertViewWithMessage:[NSString stringWithFormat:@"openURL:\n%@", url]];
  return NO;
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *))restorationHandler {
  // Show the deep link URL from userActivity.
  NSString *message = [NSString stringWithFormat:@"continueUserActivity webPageURL:\n%@",
                       userActivity.webpageURL];
  [self showDeepLinkAlertViewWithMessage:message];

  GINReceivedInvite *invite = [GINDeepLink continueUserActivity:userActivity
                                             restorationHandler:restorationHandler];
  if (invite.deepLink) {
    [self application:application
              openURL:[NSURL URLWithString:invite.deepLink]
    sourceApplication:@"com.apple.mobilesafari"
           annotation:@{}];
    return YES;
  }
  return NO;
}

- (void)showDeepLinkAlertViewWithMessage:(NSString *)message {
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Deep-link Data"
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
  [alertView show];
}

@end