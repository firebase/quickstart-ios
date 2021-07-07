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
import FirebaseAuthUI

@UIApplicationMain
// [START signin_delegate]
class AppDelegate: UIResponder, UIApplicationDelegate {
  // [END signin_delegate]

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [
                     UIApplication.LaunchOptionsKey: Any
                   ]?) -> Bool {
    // [START firebase_configure]
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    // [END firebase_configure]
    if Auth.auth().currentUser == nil {
      window?.rootViewController = SignInViewController()
    }
    return true
  }

  @available(iOS 9.0, *)
  func application(_ app: UIApplication, open url: URL,
                   options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    guard let sourceApplication =
      options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String else {
      return false
    }
    return handleOpenUrl(url, sourceApplication: sourceApplication)
  }

  @available(iOS 8.0, *)
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?,
                   annotation: Any) -> Bool {
    return handleOpenUrl(url, sourceApplication: sourceApplication)
  }

  func handleOpenUrl(_ url: URL, sourceApplication: String?) -> Bool {
    return FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false
  }
}
