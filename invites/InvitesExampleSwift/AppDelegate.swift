//
//  Copyright (c) Google Inc.
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
import FirebaseInvites
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  // [START configure]
  func application(application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Use Firebase library to configure APIs
    FIRApp.configure()
    return true
  }
  // [END configure]

  // [START openurl]
  @available(iOS 9.0, *)
  func application(application: UIApplication, openURL url: NSURL, options: [String : AnyObject])
    -> Bool {
      return self.application(application, openURL: url, sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String, annotation: "")
  }

  func application(application: UIApplication,
    openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
      if let invite = FIRInvites.handleURL(url, sourceApplication:sourceApplication, annotation:annotation) as? FIRReceivedInvite {
        let matchType =
            (invite.matchType == FIRReceivedInviteMatchType.Weak) ? "Weak" : "Strong"
        print("Invite received from: \(sourceApplication) Deeplink: \(invite.deepLink)," +
            "Id: \(invite.inviteId), Type: \(matchType)")
        return true
      }

      return GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApplication, annotation: annotation)
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
      let message = "continueUserActivity webPageURL:\n\(userActivity.webpageURL?.absoluteString)"
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
    let message = "App URL: \(dynamicLink.url?.absoluteString)\nMatch Confidence: \(matchConfidence)\n"
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

