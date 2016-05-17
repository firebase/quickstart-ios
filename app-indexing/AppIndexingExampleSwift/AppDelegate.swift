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

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var currentDeepLink: NSURL?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    FIRApp.configure()

    // [START register_app]
    // Replace 123456 with the App Store ID of your app.
    // Registering your application allows your app to be included in
    // Google Search results.
    FIRAppIndexing.sharedInstance().registerApp(123456)
    // [END register_app]
    return true
  }

  // [START handle_link]
  func application(application: UIApplication,
                   openURL url: NSURL,
                   sourceApplication: String?,
                   annotation: AnyObject) -> Bool {
    currentDeepLink = url
    return true;
  }
  // [END handle_link]

  // [START handle_universal_link]
  @available(iOS 8.0, *)
  func application(application: UIApplication,
                   continueUserActivity userActivity: NSUserActivity,
                   restorationHandler: ([AnyObject]?) -> Void) -> Bool {
    currentDeepLink = userActivity.webpageURL
    return true
  }
  // [END handle_universal_link]

}
