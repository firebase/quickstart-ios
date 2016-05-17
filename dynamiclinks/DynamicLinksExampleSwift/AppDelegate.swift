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
import FirebaseDynamicLinks
// [END import]
import Firebase


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let CUSTOM_URL_SCHEME = "dlscheme"

  // [START didfinishlaunching]
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Set deepLinkURLScheme to the custom URL scheme you defined in your
    // Xcode project.
    FIROptions.defaultOptions().deepLinkURLScheme = self.CUSTOM_URL_SCHEME
    FIRApp.configure()

    return true
  }
  // [END didfinishlaunching]

  // [START openurl]
  func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    return application(app, openURL: url, sourceApplication: nil, annotation: [:])
  }

  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    let dynamicLink = FIRDynamicLinks.dynamicLinks()?.dynamicLinkFromCustomSchemeURL(url)
    if let dynamicLink = dynamicLink {
      // Handle the deep link. For example, show the deep-linked content or
      // apply a promotional offer to the user's account.
      // [START_EXCLUDE]
      // In this sample, we just open an alert.
      let message = generateDynamicLinkMessage(dynamicLink)
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
    let handled = FIRDynamicLinks.dynamicLinks()?.handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
      // [START_EXCLUDE]
      let message = self.generateDynamicLinkMessage(dynamiclink!)
      self.showDeepLinkAlertViewWithMessage(message)
    // [END_EXCLUDE]
    }

    // [START_EXCLUDE silent]
    if (!handled!) {
      // Show the deep link URL from userActivity.
      let message = "continueUserActivity webPageURL:\n\(userActivity.webpageURL)"
      showDeepLinkAlertViewWithMessage(message)
    }
    // [END_EXCLUDE]

    return handled!
  }
  // [END continueuseractivity]

  func generateDynamicLinkMessage(dynamicLink: FIRDynamicLink) -> String {
    let matchConfidence: String
    if (dynamicLink.matchConfidence == .Weak) {
      matchConfidence = "Weak";
    } else {
      matchConfidence = "Strong";
    }
    let message = "App URL: \(dynamicLink.url)\nMatch Confidence: \(matchConfidence)\n"
    return message;
  }

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

