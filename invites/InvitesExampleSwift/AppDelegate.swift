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
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  // [START configure]
  func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    return true
  }
  // [END configure]

  // [START openurl]
  @available(iOS 9.0, *)
  func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
      return self.application(application, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: "")
  }

  func application(_ application: UIApplication,
    open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    if GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation) {
      return true
    }

    return Invites.handleUniversalLink(url) { invite, error in
      // [START_EXCLUDE]
      if let error = error {
        print(error.localizedDescription)
        return
      }
      if let invite = invite {
        self.showAlertView(withInvite: invite)
      }
      // [END_EXCLUDE]
    }
  }
  // [END openurl]

  // [START continueuseractivity]
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    return Invites.handleUniversalLink(userActivity.webpageURL!) { invite, error in
      // [START_EXCLUDE]
      if let error = error {
        print(error.localizedDescription)
        return
      }
      if let invite = invite {
        self.showAlertView(withInvite: invite)
      }
      // [END_EXCLUDE]
    }
  }
  // [END continueuseractivity]

  func showAlertView(withInvite invite: ReceivedInvite) {
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    let matchType = invite.matchType == .weak ? "weak" : "strong"
    let message = "Invite ID: \(invite.inviteId)\nDeep-link: \(invite.deepLink)\nMatch Type: \(matchType)"
    let alertController = UIAlertController(title: "Invite", message: message, preferredStyle: .alert)
    alertController.addAction(okAction)
    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
  }
}

