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
@import FirebaseInvites;
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
- (BOOL)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<NSString *, id> *)options {
  return [self application:application
                   openURL:url
         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  // Handle App Invite requests
  FIRReceivedInvite *invite =
      [FIRInvites handleURL:url sourceApplication:sourceApplication annotation:annotation];
  if (invite) {
    NSString *matchType =
        (invite.matchType == FIRReceivedInviteMatchTypeWeak) ? @"Weak" : @"Strong";
    NSString *message =
        [NSString stringWithFormat:@"Deep link from %@ \nInvite ID: %@\nApp URL: %@\nMatch Type:%@",
                                   sourceApplication, invite.inviteId, invite.deepLink, matchType];

    [[[UIAlertView alloc] initWithTitle:@"Deep-link Data"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];

    return YES;
  }

  return [[GIDSignIn sharedInstance] handleURL:url
                             sourceApplication:sourceApplication
                                    annotation:annotation];
}
// [END openurl]

// [START continueuseractivity]
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *))restorationHandler {
  // [START_EXCLUDE silent]
  NSLog(@"%@", userActivity.webpageURL);
  __weak AppDelegate *weakSelf = self;
  // [END_EXCLUDE]

  BOOL handled = [[FIRDynamicLinks dynamicLinks]
                     handleUniversalLink:userActivity.webpageURL
                              completion:^(FIRDynamicLink * _Nullable dynamicLink,
                                           NSError * _Nullable error) {
    // [START_EXCLUDE]
    AppDelegate *strongSelf = weakSelf;
    NSString *message = [strongSelf generateDynamicLinkMessage:dynamicLink];
    [strongSelf showDeepLinkAlertViewWithMessage:message];
    // [END_EXCLUDE]
  }];

  // [START_EXCLUDE silent]
  if (!handled) {
    // Show the deep link URL from userActivity.
    NSString *message =
    [NSString stringWithFormat:@"continueUserActivity webPageURL:\n%@",
        userActivity.webpageURL.absoluteString];
    [self showDeepLinkAlertViewWithMessage:message];
  }
  // [END_EXCLUDE]

  return handled;
}
// [END continueuseractivity]

- (NSString *)generateDynamicLinkMessage:(FIRDynamicLink *)dynamicLink {
  NSString *matchConfidence;
  if (dynamicLink.matchConfidence == FIRDynamicLinkMatchConfidenceStrong) {
    matchConfidence = @"strong";
  } else {
    matchConfidence = @"weak";
  }

  NSString *msg = [NSString stringWithFormat:@"App URL: %@\n"
                       @"Match Confidence: %@\n",
                       dynamicLink.url.absoluteString, matchConfidence];
  return msg;
}

- (void)showDeepLinkAlertViewWithMessage:(NSString *)message {
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];

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
