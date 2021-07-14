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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // [START firebase_configure]
  // Use Firebase library to configure APIs
  [FIRApp configure];
  // [END firebase_configure]

  [[FBSDKApplicationDelegate sharedInstance] application:application
                           didFinishLaunchingWithOptions:launchOptions];
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
  if ([[GIDSignIn sharedInstance] handleURL:url]) {
    return YES;
  }
  return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                        openURL:url
  // [START old_options]
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
}
// [END old_options]

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
#else
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray * __nullable restorableObjects))restorationHandler {
#endif
  return [self handlePasswordlessSignInWithLink:userActivity.webpageURL];
}

- (BOOL)handlePasswordlessSignInWithLink:(nonnull NSURL*)url {
  NSString *link = url.absoluteString;
  // [START is_signin_link]
  if ([[FIRAuth auth] isSignInWithEmailLink:link]) {
    // [END is_signin_link]
    [NSUserDefaults.standardUserDefaults setObject:link forKey:@"Link"];
    [(UINavigationController*)_window.rootViewController popToRootViewControllerAnimated:NO];
    [_window.rootViewController.childViewControllers[0] performSegueWithIdentifier:@"passwordless" sender:nil];
    return YES;
  }
  return NO;
}

@end
