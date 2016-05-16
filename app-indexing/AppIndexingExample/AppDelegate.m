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
@import Firebase;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [FIRApp configure];

  // [START register_app]
  // Replace 123456 with the App Store ID of your app.
  // Registering your application allows your app to be included in
  // Google Search results.
  [[FIRAppIndexing sharedInstance] registerApp:123456];
  // [END register_app]
  return YES;
}

// [START handle_link]
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  self.currentDeepLink = url;
  return YES;
}
// [END handle_link]

// [START handle_universal_link]
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
  self.currentDeepLink = [userActivity webpageURL];
  return YES;
}
// [END handle_universal_link]

@end
