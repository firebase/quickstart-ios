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
import FirebaseAuthUI
import Firebase.Core

@objc(SelectViewController)
class SelectViewController: UIViewController {

  /*! @var kOKButtonText
  @brief The text of the "OK" button for the Sign In result dialogs.
  */
  let kOKButtonText = "OK"

  /*! @var kSignedInAlertTitle
  @brief The text of the "Sign In Succeeded" alert.
  */
  let kSignedInAlertTitle = "Signed In"

  /*! @var kSignInErrorAlertTitle
  @brief The text of the "Sign In Encountered an Error" alert.
  */
  let kSignInErrorAlertTitle = "Sign-In Error"

  @IBAction func didUISignIn(sender: UIButton) {
    // [START firebase_auth_ui]
    let firebaseAuth = FIRAuth.auth()
    let firebaseAuthUI: FIRAuthUI = FIRAuthUI.init(forApp: (firebaseAuth?.app)!)!
    firebaseAuthUI.presentSignInWithViewController(self) { (user, error) in
      // [END firebase_auth_ui]
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default)
        {action in print(self.kOKButtonText)}
      if let error = error {
        let alertController = UIAlertController.init(title: self.kSignInErrorAlertTitle,
          message: error.localizedDescription, preferredStyle: .Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        return
      }

      // Log token refresh event to Firebase Analytics.
      FIRAnalytics.logEventWithName(kFIREventLogin, parameters: nil)

      self.performSegueWithIdentifier("UISignIn", sender:nil)
    }
  }

  @IBAction func didTapGuestSignIn(sender: AnyObject) {
    // [START firebase_auth_anonymous]
    FIRAuth.auth()?.signInAnonymouslyWithCallback() { (user, error) in
    // [END firebase_auth_anonymous]
      if let error = error {
        print(error.localizedDescription)
        return
      }
      self.performSegueWithIdentifier("UISignIn", sender:nil)
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  }
}
