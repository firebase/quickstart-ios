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
@import Firebase;
// [END import]

static NSString *const CUSTOM_URL_SCHEME = @"dlscheme";

@implementation AppDelegate

// [START didfinishlaunching]
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set deepLinkURLScheme to the custom URL scheme you defined in your
  // Xcode project.
  [FIROptions defaultOptions].deepLinkURLScheme = CUSTOM_URL_SCHEME;
  [FIRApp configure];

  return YES;
}
// [END didfinishlaunching]

// [START openurl]
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
  return [self application:app
                   openURL:url
         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  FIRDynamicLink *dynamicLink = [[FIRDynamicLinks dynamicLinks] dynamicLinkFromCustomSchemeURL:url];

  if (dynamicLink) {
    if (dynamicLink.url) {
      // Handle the deep link. For example, show the deep-linked content,
      // apply a promotional offer to the user's account or show customized onboarding view.
      // [START_EXCLUDE]
      // In this sample, we just open an alert.
      [self handleDynamicLink:dynamicLink];
      // [END_EXCLUDE]
    } else {
      // Dynamic link has empty deep link. This situation will happens if
      // Firebase Dynamic Links iOS SDK tried to retrieve pending dynamic link,
      // but pending link is not available for this device/App combination.
      // At this point you may display default onboarding view.
    }
    return YES;
  }
  // [START_EXCLUDE silent]
  // Show the deep link that the app was called with.
  [self showDeepLinkAlertViewWithMessage:[NSString stringWithFormat:@"openURL:\n%@", url]];
  // [END_EXCLUDE]
  return NO;
}
// [END openurl]

// [START continueuseractivity]
- (BOOL)application:(UIApplication *)application
continueUserActivity:(nonnull NSUserActivity *)userActivity
 restorationHandler:
#if defined(__IPHONE_12_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0)
(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))restorationHandler {
#else
    (nonnull void (^)(NSArray *_Nullable))restorationHandler {
#endif  // __IPHONE_12_0
  BOOL handled = [[FIRDynamicLinks dynamicLinks] handleUniversalLink:userActivity.webpageURL
                                                          completion:^(FIRDynamicLink * _Nullable dynamicLink,
                                                                       NSError * _Nullable error) {
                                                            // [START_EXCLUDE]
                                                            [self handleDynamicLink:dynamicLink];
                                                            // [END_EXCLUDE]
                                                          }];
  // [START_EXCLUDE silent]
  if (!handled) {
    // Show the deep link URL from userActivity.
    NSString *message = [NSString stringWithFormat:@"continueUserActivity webPageURL:\n%@",
                         userActivity.webpageURL];
    [self showDeepLinkAlertViewWithMessage:message];
  }
  // [END_EXCLUDE]
  return handled;
}
// [END continueuseractivity]

- (void)handleDynamicLink:(FIRDynamicLink *)dynamicLink {
  NSString *matchConfidence;
  if (dynamicLink.matchType == FIRDLMatchTypeWeak) {
    matchConfidence = @"Weak";
  } else {
    matchConfidence = @"Strong";
  }
  NSString *message = [NSString stringWithFormat:@"App URL: %@\n"
                       @"Match Confidence: %@\nMinimum App Version:%@",
                       dynamicLink.url, matchConfidence, dynamicLink.minimumAppVersion];
  [self showDeepLinkAlertViewWithMessage:message];
}

- (void)showDeepLinkAlertViewWithMessage:(NSString *)message {
  NSString *title = @"Deep-link Data";
  NSString *buttonTitle = @"OK";

  if ([UIAlertController class]) {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:buttonTitle
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    UIViewController *rootViewController = self.window.rootViewController;
    [rootViewController presentViewController:alert animated:YES completion:nil];
  } else {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:buttonTitle
                                              otherButtonTitles:nil];
    [alertView show];
  }
}

@end
