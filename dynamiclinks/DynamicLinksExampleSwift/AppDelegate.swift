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
import FirebaseAnalytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let CUSTOM_URL_SCHEME = "gindeeplinkurl"

  // [START didfinishlaunching]
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Set deepLinkURLScheme to the custom URL scheme you defined in your
    // Xcode project.
    FIROptions.defaultOptions().deepLinkURLScheme = self.CUSTOM_URL_SCHEME
    FIRApp.configure()
    GINDurableDeepLinkService.sharedInstance().checkForPendingDeepLink()

    return true
  }
  // [END didfinishlaunching]

  // [START openurl]
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    let deepLink:GINDeepLink? = GINDurableDeepLinkService.sharedInstance().deepLinkFromCustomSchemeURL(url)
    if (deepLink != nil) {
      // Handle the deep link. For example, show the deep-linked content or
      // apply a promotional offer to the user's account.
      // [START_EXCLUDE]
      // In this sample, we just open an alert.
      let matchConfidence: String
      if (deepLink!.matchConfidence == GINDeepLinkMatchConfidence.Weak) {
        matchConfidence = "Weak";
      } else {
        matchConfidence = "Strong";
      }
      let message = "App URL: \(deepLink!.url)\nMatch Confidence: \(matchConfidence)\n"
      if #available(iOS 8.0, *) {
          showDeepLinkAlertViewWithMessage(message)
      } else {
          // Fallback on earlier versions
      }
      // [END_EXCLUDE]
      return true
    }

    // [START_EXCLUDE silent]
    // Show the deep link that the app was called with.
    if #available(iOS 8.0, *) {
        showDeepLinkAlertViewWithMessage("openURL:\n\(url)")
    } else {
        // Fallback on earlier versions
    }
    // [END_EXCLUDE]
    return false
  }
  // [END openurl]

  // [START continueuseractivity]
  @available(iOS 8.0, *)
  func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
    // [START_EXCLUDE silent]
    // Show the deep link URL from userActivity.
    let message = "continueUserActivity webPageURL:\n\(userActivity.webpageURL)"
    showDeepLinkAlertViewWithMessage(message)
    // [END_EXCLUDE]
    return GINDurableDeepLinkService.sharedInstance().handleUniversalLink(userActivity.webpageURL) { (deepLink, error) in
      // Handle the deep link. For example, show the deep-linked content or apply
      // a promotional offer to the user's account.
      // [START_EXCLUDE]
      // the source application needs to be safari or chrome, otherwise
      // GIDSignIn will not handle the URL.
      self.application(application, openURL: deepLink!.url!, sourceApplication: "com.apple.mobilesafari", annotation: [:])
      // [END_EXCLUDE]
    })
  }
  // [END continueuseractivity]

  @available(iOS 8.0, *)
  func showDeepLinkAlertViewWithMessage(message: String) {
    let okAction = UIAlertAction.init(title: "OK", style: .Default) { (action) -> Void in
      print("OK")
    }

    let alertController = UIAlertController.init(title: "Deep-link Data", message: message, preferredStyle: .Alert)
    alertController.addAction(okAction)
    self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
  }


}

