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
// [END usermanagement_view_import]

@objc(CustomViewController)
class CustomViewController: UIViewController {

  /*! @var kSignedInAlertTitle
  @brief The text of the "Sign In Succeeded" alert.
  */
  let kSignedInAlertTitle = "Signed In"

  /*! @var kSignInErrorAlertTitle
  @brief The text of the "Sign In Encountered an Error" alert.
  */
  let kSignInErrorAlertTitle = "Sign-In Error"

  /*! @var kOKButtonText
  @brief The text of the "OK" button for the Sign In result dialogs.
  */
  let kOKButtonText = "OK"

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!

  @IBAction func didTapEmailLogin(sender: AnyObject) {
    // [START headless_email_auth]
    FIRAuth.auth()?.signInWithEmail(emailField.text!, password: passwordField.text!) { (user, error) in
      // [END headless_email_auth]
      if let error = error {
        self.showMessagePrompt(error.localizedDescription)
        return
      }

      self.showMessagePrompt(user!.displayName ?? "Display name is not set for user")
      self.performSegueWithIdentifier("EmailSignIn", sender: nil)
    }
  }

  /** @fn requestPasswordReset
  @brief Requests a "password reset" email be sent.
  */
  @IBAction func didRequestPasswordReset(sender: AnyObject) {
    showTextInputPromptWithMessage("Email:") { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        // [START password_reset]
        FIRAuth.auth()!.sendPasswordResetWithEmail(userInput!) { (error) in
          // [END password_reset]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }

            self.showMessagePrompt("Sent")
          })
        }
      })
    }
  }

  /** @fn getProvidersForEmail
  @brief Prompts the user for an email address, calls @c FIRAuth.getProvidersForEmail:callback:
  and displays the result.
  */
  @IBAction func didGetProvidersForEmail(sender: AnyObject) {
    showTextInputPromptWithMessage("Email:") { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        // [START get_providers]
        FIRAuth.auth()!.getProvidersForEmail(userInput!) { (providers, error) in
          // [END get_providers]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }

            self.showMessagePrompt(providers!.joinWithSeparator(", "))
          })
        }
      })
    }
  }

  @IBAction func didCreateAccount(sender: AnyObject) {
    showTextInputPromptWithMessage("Email:") { (userPressedOK, email) in
      if (userPressedOK != true) || email!.isEmpty {
        return
      }

      self.showTextInputPromptWithMessage("Password:") { (userPressedOK, password) in
        if (userPressedOK != true) || password!.isEmpty {
          return
        }

        self.showSpinner({
          // [START create_user]
          FIRAuth.auth()!.createUserWithEmail(email!, password: password!) { (user, error) in
            // [END create_user]
            self.hideSpinner({
              if let error = error {
                self.showMessagePrompt(error.localizedDescription)
                return
              }

              self.showMessagePrompt(user!.email!)
            })
          }
        })
      }
    }
  }
}