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

import FirebaseAuth
import Firebase.Core

@objc(FBLoginViewController)
class FBLoginViewController: UIViewController, FBSDKLoginButtonDelegate {

  @IBOutlet weak var facebookLoginButton: FBSDKLoginButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    let loginButton = FBSDKLoginButton()
    loginButton.delegate = self
  }

  func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError?) {
    if let error = error {
      print(error.localizedDescription)
      return
    }

    // [START headless_facebook_auth]
    let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)

    // [START_EXCLUDE]
    showSpinner({
      // [END_EXCLUDE]
      FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
        // [END headless_facebook_auth]
        self.hideSpinner({
          if let error = error {
            self.showMessagePrompt(error.localizedDescription)
            return
          }
          self.performSegueWithIdentifier("FBLogin", sender: nil)
        })
      }
    })
  }

  func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    self.showMessagePrompt("User logged out!")
  }

}
