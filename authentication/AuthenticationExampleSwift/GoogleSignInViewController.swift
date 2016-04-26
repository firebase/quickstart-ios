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

//
// For more information on setting up and running this sample code, see
// https://developers.google.com/firebase/docs/auth/ios/user-auth
//

import UIKit

import Firebase
import FirebaseAuth
import GoogleSignIn

@objc(GoogleSignInViewController)
class GoogleSignInViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {

  @IBOutlet weak var signInButton: GIDSignInButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
    GIDSignIn.sharedInstance().uiDelegate = self

    // TODO(developer): Configure the sign-in button look/feel
    GIDSignIn.sharedInstance().delegate = self
  }

  // [START headless_google_auth]
  func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError?) {
    if let error = error {
      print(error.localizedDescription)
      return
    }

    let authentication = user.authentication
    let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)

    // [START_EXCLUDE]
    showSpinner({
      // [END_EXCLUDE]
      FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
        // [END headless_google_auth]
        self.hideSpinner({
          if let error = error {
            print(error.localizedDescription)
            return
          }
          self.performSegueWithIdentifier("GoogleSignIn", sender: nil)
        })
      }
    })
  }

}
