//
//  Copyright (c) Google Inc.
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
@import GoogleSignIn;

@implementation AppDelegate

// [START configure]
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Use Firebase library to configure APIs
  [FIRApp configure];
  return YES;
}
// [END configure]

// [START openurl]
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
  return [self application:app
                   openURL:url
         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  if ([[GIDSignIn sharedInstance] handleURL:url
                      sourceApplication:sourceApplication
                                 annotation:annotation]) {
    return YES;
  }
  // Handle App Invite requests
  return [FIRInvites handleUniversalLink:url
                              completion:^(FIRReceivedInvite * _Nullable receivedInvite,
                                           NSError * _Nullable error) {
    // [START_EXCLUDE]
    if (receivedInvite) {
      [self showAlertViewWithInvite:receivedInvite];
    }
    // [END_EXCLUDE]
  }];
}
// [END openurl]

// [START continueuseractivity]
- (BOOL)application:(UIApplication *)application
continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:
#if defined(__IPHONE_12_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0)
(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))restorationHandler {
#else
    (nonnull void (^)(NSArray *_Nullable))restorationHandler {
#endif  // __IPHONE_12_0
  // Handle App Invite requests
  return [FIRInvites handleUniversalLink:userActivity.webpageURL
                              completion:^(FIRReceivedInvite * _Nullable receivedInvite,
                                           NSError * _Nullable error) {
    // [START_EXCLUDE]
    if (receivedInvite) {
      [self showAlertViewWithInvite:receivedInvite];
    }
    // [END_EXCLUDE]
  }];
}
// [END continueuseractivity]

- (void)showAlertViewWithInvite:(FIRReceivedInvite *)invite {
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
  NSString *matchType = invite.matchType == FIRReceivedInviteMatchTypeWeak ? @"weak" : @"strong";
  NSString *message =
  [NSString stringWithFormat:@"Invite ID: %@\nDeep-link: %@\nMatch Type: %@",
   invite.inviteId, invite.deepLink, matchType];

  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:@"Invite"
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:okAction];
  [self.window.rootViewController presentViewController:alertController
                                               animated:YES
                                             completion:nil];
}
@end
