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
// [START import]
import Firebase
// [END import]

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let customURLScheme = "dlscheme"

  // [START didfinishlaunching]
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Set deepLinkURLScheme to the custom URL scheme you defined in your
    // Xcode project.
    FirebaseOptions.defaultOptions()?.deepLinkURLScheme = self.customURLScheme
    FirebaseApp.configure()

    return true
  }
  // [END didfinishlaunching]

  // [START openurl]
  @available(iOS 9.0, *)
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    return application(app, open: url,
                       sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                       annotation: "")
  }

  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
      // Handle the deep link. For example, show the deep-linked content or
      // apply a promotional offer to the user's account.
      // [START_EXCLUDE]
      // In this sample, we just open an alert.
      handleDynamicLink(dynamicLink)
      // [END_EXCLUDE]
      return true
    }
    // [START_EXCLUDE silent]
    // Show the deep link that the app was called with.
    showDeepLinkAlertView(withMessage: "openURL:\n\(url)")
    // [END_EXCLUDE]
    return false
  }
  // [END openurl]

  // [START continueuseractivity]
  func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
      // [START_EXCLUDE]
      if let dynamiclink = dynamiclink {
        self.handleDynamicLink(dynamiclink)
      }
      // [END_EXCLUDE]
    }

    // [START_EXCLUDE silent]
    if !handled {
      // Show the deep link URL from userActivity.
      let message = "continueUserActivity webPageURL:\n\(userActivity.webpageURL?.absoluteString ?? "")"
      showDeepLinkAlertView(withMessage: message)
    }
    // [END_EXCLUDE]
    return handled
  }
  // [END continueuseractivity]

  func handleDynamicLink(_ dynamicLink: DynamicLink) {
    let matchConfidence: String
    if dynamicLink.matchType == .weak {
      matchConfidence = "Weak"
    } else {
      matchConfidence = "Strong"
    }
    let message = "App URL: \(dynamicLink.url?.absoluteString ?? "")\n" +
        "Match Confidence: \(matchConfidence)\nMinimum App Version: \(dynamicLink.minimumAppVersion ?? "")"
    showDeepLinkAlertView(withMessage: message)
  }

  func showDeepLinkAlertView(withMessage message: String) {
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    let alertController = UIAlertController(title: "Deep-link Data", message: message, preferredStyle: .alert)
    alertController.addAction(okAction)
    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
  }

}
