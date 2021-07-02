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

import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication
                     .LaunchOptionsKey: Any]?) -> Bool {
    // Uncomment the following line to disable In-App Messaging auto-startup.
    // InAppMessaging.inAppMessaging().automaticDataCollectionEnabled = false

    FirebaseOptions.defaultOptions()?.deepLinkURLScheme = "com.google.InAppMessagingExampleSwiftiOS"
    FirebaseApp.configure()
    return true
  }

  func application(_ app: UIApplication,
                   open url: URL,
                   options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return application(app,
                       open: url,
                       sourceApplication: options[.sourceApplication] as? String,
                       annotation: options[.annotation] as Any)
  }

  func application(_ application: UIApplication,
                   open url: URL,
                   sourceApplication: String?,
                   annotation: Any) -> Bool {
    let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)

    if dynamicLink != nil {
      if dynamicLink?.url != nil {
        // Handle the deep link. For example, show the deep-linked content,
        // apply a promotional offer to the user's account or show customized onboarding view.
        // ...
      } else {
        // Dynamic link has empty deep link. This situation will happens if
        // Firebase Dynamic Links iOS SDK tried to retrieve pending dynamic link,
        // but pending link is not available for this device/App combination.
        // At this point you may display default onboarding view.
      }
      return true
    }
    return false
  }
}
