//
//  Copyright (c) 2018 Google Inc.
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
  var didBackground: Bool?
    
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize Firebase service.
    FirebaseApp.configure()
    return true
  }
   
  /**
  * Set up a pair of custom keys to track whether the app was in the background or had been backgrounded at some point.
  */
  func applicationWillResignActive(_ application: UIApplication) {
    Crashlytics.crashlytics().setCustomValue(true, forKey: "in_background")
    didBackground = true
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    Crashlytics.crashlytics().setCustomValue(false, forKey: "in_background")
    if (didBackground!) {
      Crashlytics.crashlytics()
        .setCustomValue(true, forKey: "was_backgrounded")
    }
  }
}
