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

// [START usermanagement_view_import]
import FirebaseAuth
import Firebase.Core
import FirebaseFacebookAuthProvider
import FirebaseGoogleAuthProvider
// [END usermanagement_view_import]

@objc(CustomViewController)
class CustomViewController: UIViewController {

  /*! @var kSignedInAlertTitle
  @brief The text of the "Sign In Succeeded" alert.
  */
  var kSignedInAlertTitle = "Signed In"

  /*! @var kSignInErrorAlertTitle
  @brief The text of the "Sign In Encountered an Error" alert.
  */
  var kSignInErrorAlertTitle = "Sign-In Error"

  /*! @var kOKButtonText
  @brief The text of the "OK" button for the Sign In result dialogs.
  */
  var kOKButtonText = "OK"

  @IBOutlet weak var facebookTokenField: UITextField!
  @IBOutlet weak var idTokenfield: UITextField!
  @IBOutlet weak var accessTokenField: UITextField!
  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!

  @IBAction func didTapFacebookLogin(sender: AnyObject) {
    let credential = FIRFacebookAuthProvider.credentialWithAccessToken(facebookTokenField.text)

    FIRAuth.auth().signInWithCredential(credential) {
      (user: FIRUser?, error: NSError?) -> Void in
      if (error != nil) {
        self.showMessagePrompt(error!.localizedDescription)
        return
      }

      self.showMessagePrompt(user.displayName)
      self.performSegueWithIdentifier("CustomSignIn", sender:nil)
    }
  }

  @IBAction func didTapGoogleLogin(sender: AnyObject) {
  }

  @IBAction func didTapEmailLogin(sender: AnyObject) {
  }
}
