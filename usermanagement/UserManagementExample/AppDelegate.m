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
#import "ViewController.h"

// [START usermanagement_import]
#import "Firebase/Core.h"
#import "FirebaseAuth/FIRAuth.h"
#import "FirebaseApp/FIRFirebaseApp.h"
#import "FirebaseApp/FIRFirebaseOptions.h"
#import "FirebaseAuth/FIRGoogleSignInAuthProvider.h"
// [END usermanagement_import]

/*! @var kWidgetURL
 @brief The GITkit widget URL.
 */
static NSString *const kWidgetURL = @"https://gitkitmobile.appspot.com/gitkit.jsp";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // [START firebase_configure]
  // Use Firebase library to configure APIs
  NSError *configureError;
  BOOL status = [[FIRContext sharedInstance] configure:&configureError];
  NSAssert(status, @"Error configuring Firebase services: %@", configureError);
  // [END firebase_configure]

  // [START usermanagement_initialize]
  // Configure the default Firebase application
  FIRGoogleSignInAuthProvider *googleSignIn =
  [[FIRGoogleSignInAuthProvider alloc] initWithClientId:
      [FIRContext sharedInstance].serviceInfo.clientID];

  FIRFirebaseOptions *firebaseOptions = [[FIRFirebaseOptions alloc] init];
  firebaseOptions.GITkitAPIKey = [FIRContext sharedInstance].serviceInfo.apiKey;
  firebaseOptions.GITkitWidgetURL = [NSURL URLWithString:kWidgetURL];
  firebaseOptions.signInProviders = @[ googleSignIn ];
  [FIRFirebaseApp initializedAppWithAppId:[FIRContext sharedInstance].serviceInfo.googleAppID
                                  options:firebaseOptions];
  // [END usermanagement_initialize]

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

@end
