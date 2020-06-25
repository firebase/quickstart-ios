//
//  Copyright (c) 2016 Google Inc.
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

// [START auth_import]
import Firebase
// [END auth_import]

// [START google_import]
import GoogleSignIn
// [END google_import]
import FBSDKCoreKit

@UIApplicationMain
// [START signin_delegate]
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
// [END signin_delegate]

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions
      launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // [START firebase_configure]
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    // [END firebase_configure]

    // [START setup_gidsignin]
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().delegate = self
    // [END setup_gidsignin]

    ApplicationDelegate.shared.application(application,
        didFinishLaunchingWithOptions:launchOptions)

    return true
  }

  // [START new_delegate]
  @available(iOS 9.0, *)
  func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
    -> Bool {
      // [END new_delegate]
      return self.application(application,
                              open: url,
                              // [START new_options]
                              sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                              annotation: [:])
  }
  // [END new_options]

  // [START old_delegate]
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    // [END old_delegate]
    if handlePasswordlessSignIn(withURL: url) {
      return true
    }
    if GIDSignIn.sharedInstance().handle(url) {
      return true
    }
    return ApplicationDelegate.shared.application(application,
                                                            open: url,
                                                            // [START old_options]
                                                            sourceApplication: sourceApplication,
                                                            annotation: annotation)
  }
  // [END old_options]

  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    return userActivity.webpageURL.flatMap(handlePasswordlessSignIn)!
  }

  func handlePasswordlessSignIn(withURL url: URL) -> Bool {
    let link = url.absoluteString
    // [START is_signin_link]
    if Auth.auth().isSignIn(withEmailLink: link) {
      // [END is_signin_link]
      UserDefaults.standard.set(link, forKey: "Link")
      (window?.rootViewController as? UINavigationController)?.popToRootViewController(animated: false)
      window?.rootViewController?.children[0].performSegue(withIdentifier: "passwordless", sender: nil)
      return true
    }
    return false
  }

  // [START headless_google_auth]
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
    // [START_EXCLUDE]
    guard let controller = GIDSignIn.sharedInstance().presentingViewController as? MainViewController else { return }
    // [END_EXCLUDE]
    if let error = error {
      // [START_EXCLUDE]
      controller.showMessagePrompt(error.localizedDescription)
      // [END_EXCLUDE]
      return
    }

    // [START google_credential]
    guard let authentication = user.authentication else { return }
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                      accessToken: authentication.accessToken)
    // [END google_credential]
    // [START_EXCLUDE]
    controller.firebaseLogin(credential)
    // [END_EXCLUDE]
  }
  // [END headless_google_auth]
}
