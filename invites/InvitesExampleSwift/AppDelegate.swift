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
  func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Use Firebase library to configure APIs
    FIRApp.configure()
    return true
  }
  // [END configure]

  // [START openurl]
  @available(iOS 9.0, *)
  func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
    -> Bool {
      return self.application(application, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: "")
  }

  func application(_ application: UIApplication,
    open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      if let invite = FIRInvites.handle(url, sourceApplication:sourceApplication, annotation:annotation) as? FIRReceivedInvite {
        let matchType =
            (invite.matchType == .weak) ? "Weak" : "Strong"
        print("Invite received from: \(sourceApplication) Deeplink: \(invite.deepLink)," +
            "Id: \(invite.inviteId), Type: \(matchType)")
        return true
      }

      return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
  }
  // [END openurl]

  // [START continueuseractivity]
  @available(iOS 8.0, *)
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    let handled = FIRDynamicLinks.dynamicLinks()?.handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
      // [START_EXCLUDE]
      let message = self.generateDynamicLinkMessage(dynamiclink!)
      self.showDeepLinkAlertView(withMessage: message)
      // [END_EXCLUDE]
    }

    // [START_EXCLUDE silent]
    if (!handled!) {
      // Show the deep link URL from userActivity.
      let message = "continueUserActivity webPageURL:\n\(userActivity.webpageURL?.absoluteString)"
      showDeepLinkAlertView(withMessage: message)
    }
    // [END_EXCLUDE]

    return handled!
  }
  // [END continueuseractivity]

  func generateDynamicLinkMessage(_ dynamicLink: FIRDynamicLink) -> String {
    let matchConfidence: String
    if (dynamicLink.matchConfidence == .weak) {
      matchConfidence = "Weak";
    } else {
      matchConfidence = "Strong";
    }
    let message = "App URL: \(dynamicLink.url?.absoluteString)\nMatch Confidence: \(matchConfidence)\n"
    return message;
  }

  @available(iOS 8.0, *)
  func showDeepLinkAlertView(withMessage message: String) {
    let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) -> Void in
      print("OK")
    }

    let alertController = UIAlertController.init(title: "Deep-link Data", message: message, preferredStyle: .alert)
    alertController.addAction(okAction)
    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
  }

}

