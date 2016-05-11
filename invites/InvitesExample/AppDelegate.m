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
@end
