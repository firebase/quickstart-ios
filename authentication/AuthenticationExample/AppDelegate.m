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
#import "MainViewController.h"
#import "UIViewController+Alerts.h"

// [START auth_import]
@import Firebase;
// [END auth_import]

// [START google_import]
@import GoogleSignIn;
// [END google_import]
@import FBSDKCoreKit;
@import Fabric;
@import TwitterKit;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // [START firebase_configure]
  // Use Firebase library to configure APIs
  [FIRApp configure];
  // [END firebase_configure]

  // [START setup_gidsignin]
  [GIDSignIn sharedInstance].clientID = [FIRApp defaultApp].options.clientID;
  [GIDSignIn sharedInstance].delegate = self;
  // [END setup_gidsignin]

  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];

  NSString *key = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"consumerKey"],
      *secret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"consumerSecret"];
  if ([key length] && [secret length]) {
    [[Twitter sharedInstance] startWithConsumerKey:key consumerSecret:secret];
  }
  return YES;
}

// [START new_delegate]
- (BOOL)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<NSString *, id> *)options {
  // [END new_delegate]
  return [self application:application
                   openURL:url
         // [START new_options]
         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}
// [END new_options]

// [START old_delegate]
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  // [END old_delegate]
  if ([self handlePasswordlessSignInWithLink:url]) {
    return YES;
  }
  if ([[GIDSignIn sharedInstance] handleURL:url
                          sourceApplication:sourceApplication
                                 annotation:annotation]) {
    return YES;
  }
  return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                        openURL:url
  // [START old_options]
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
}
// [END old_options]

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
  return [self handlePasswordlessSignInWithLink:userActivity.webpageURL];
}

- (BOOL)handlePasswordlessSignInWithLink:(nonnull NSURL*)url {
  NSString *link = url.absoluteString;
  if ([[FIRAuth auth] isSignInWithEmailLink:link]) {
    [NSUserDefaults.standardUserDefaults setObject:link forKey:@"Link"];
    [(UINavigationController*)_window.rootViewController popToRootViewControllerAnimated:NO];
    [_window.rootViewController.childViewControllers[0] performSegueWithIdentifier:@"passwordless" sender:nil];
    return YES;
  }
  return NO;
}

// [START headless_google_auth]
- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
  // [START_EXCLUDE]
  MainViewController *controller = (MainViewController*) [GIDSignIn sharedInstance].uiDelegate;
  // [END_EXCLUDE]
  if (error == nil) {
    // [START google_credential]
    GIDAuthentication *authentication = user.authentication;
    FIRAuthCredential *credential =
    [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken
                                     accessToken:authentication.accessToken];
    // [END google_credential]
    // [START_EXCLUDE]
    [controller firebaseLoginWithCredential:credential];
    // [END_EXCLUDE]
  } else {
    // [START_EXCLUDE]
    [controller showMessagePrompt:error.localizedDescription];
    // [END_EXCLUDE]
  }
}
// [END headless_google_auth]

@end
