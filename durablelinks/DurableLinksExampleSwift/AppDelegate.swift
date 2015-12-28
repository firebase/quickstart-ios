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
import Firebase.DurableDeepLink
import Firebase.Core
// [END import]


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  // [START didfinishlaunching]
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Use Firebase library to configure APIs
    do {
      try FIRContext.sharedInstance().configure()
    } catch let configureError as NSError{
      print ("Error configuring Firebase services: \(configureError)")
    }

    // Override point for customization after application launch.
    GINDurableDeepLinkService.sharedInstance().setUpWithLaunchOptions(launchOptions,
        apiKey: FIRContext.sharedInstance().serviceInfo.apiKey,
        clientID: FIRContext.sharedInstance().serviceInfo.clientID,
        urlScheme: "gindeeplinkurl", userDefaults: nil)
    GINDurableDeepLinkService.sharedInstance().checkForPendingDeepLink()

    return true
  }
  // [END didfinishlaunching]

  // [START openurl]
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    let deepLink:GINDeepLink? = GINDurableDeepLinkService.sharedInstance().deepLinkFromCustomSchemeURL(url)
    if (deepLink != nil) {
      // [START_EXCLUDE]
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

    // Show the deep link that the app was called with.
    if #available(iOS 8.0, *) {
        showDeepLinkAlertViewWithMessage("openURL:\n\(url)")
    } else {
        // Fallback on earlier versions
    }
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

    let deepLink = GINDurableDeepLinkService.sharedInstance().deepLinkFromUniversalLinkURL(userActivity.webpageURL!)
    if (deepLink!.url != nil) {
      self.application(application, openURL: deepLink!.url, sourceApplication: "com.apple.mobilesafari", annotation: [:])
      return true
    }
    return false
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

