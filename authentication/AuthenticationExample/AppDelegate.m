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

//
// For more information on setting up and running this sample code, see
// https://developers.google.com/firebase/docs/auth/ios/user-auth
//


#import "AppDelegate.h"

// [START usermanagement_import]
@import Firebase.Core;
@import FirebaseApp;
@import FirebaseAuth;
@import FirebaseAuthUI;
@import FirebaseFacebookAuthUI;
@import FirebaseGoogleAuthUI;
// [END usermanagement_import]

#import <GoogleSignIn/GIDSignIn.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

/** @var kFacebookAppId
 @brief The App ID for the Facebook SDK.
 */
static NSString *const kFacebookAppID = @"Placeholder";


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // [START firebase_configure]
  // Use Firebase library to configure APIs
  NSError *configureError;
  BOOL status = [[FIRContext sharedInstance] configure:&configureError];
  NSAssert(status, @"Error configuring Firebase services: %@", configureError);
  // [END firebase_configure]

  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];
  return YES;
}

- (BOOL)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<NSString *, id> *)options {
  if ([FIRFirebaseApp handleOpenURL:url
                  sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]]) {
    return YES;
  }

  return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  if ([[GIDSignIn sharedInstance] handleURL:url
                      sourceApplication:sourceApplication
                                 annotation:annotation]) {
    return YES;
  }
  return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                        openURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation
          ];
}

@end
