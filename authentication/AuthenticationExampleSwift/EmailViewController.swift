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

import Firebase

@objc(EmailViewController)
class EmailViewController: UIViewController {

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }

  @IBAction func didTapEmailLogin(_ sender: AnyObject) {
    guard let email = self.emailField.text, let password = self.passwordField.text else {
      self.showMessagePrompt("email/password can't be empty")
      return
    }
    showSpinner {
      // [START headless_email_auth]
      Auth.auth().signIn(withEmail: email, password: password) { [weak self] user, error in
        guard let strongSelf = self else { return }
        // [START_EXCLUDE]
        strongSelf.hideSpinner {
          if let error = error {
            strongSelf.showMessagePrompt(error.localizedDescription)
            return
          }
          strongSelf.navigationController?.popViewController(animated: true)
        }
        // [END_EXCLUDE]
      }
      // [END headless_email_auth]
    }
  }

  /** @fn requestPasswordReset
   @brief Requests a "password reset" email be sent.
   */
  @IBAction func didRequestPasswordReset(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Email:") { [weak self] userPressedOK, email in
      guard let strongSelf = self, let email = email else {
        return
      }
      strongSelf.showSpinner {
        // [START password_reset]
        Auth.auth().sendPasswordReset(withEmail: email) { error in
          // [START_EXCLUDE]
          strongSelf.hideSpinner {
            if let error = error {
              strongSelf.showMessagePrompt(error.localizedDescription)
              return
            }
            strongSelf.showMessagePrompt("Sent")
          }
          // [END_EXCLUDE]
        }
        // [END password_reset]
      }
    }
  }

  /** @fn getProvidersForEmail
   @brief Prompts the user for an email address, calls @c FIRAuth.getProvidersForEmail:callback:
   and displays the result.
   */
  @IBAction func didGetProvidersForEmail(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Email:") { [weak self] userPressedOK, email in
      guard let strongSelf = self else { return }
      guard let email = email else {
        strongSelf.showMessagePrompt("email can't be empty")
        return
      }
      strongSelf.showSpinner {
        // [START get_providers]
        Auth.auth().fetchProviders(forEmail: email) { providers, error in
          // [START_EXCLUDE]
          strongSelf.hideSpinner {
            if let error = error {
              strongSelf.showMessagePrompt(error.localizedDescription)
              return
            }
            strongSelf.showMessagePrompt(providers!.joined(separator: ", "))
          }
          // [END_EXCLUDE]
        }
        // [END get_providers]
      }
    }
  }

  @IBAction func didCreateAccount(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Email:") {  [weak self] userPressedOK, email in
      guard let strongSelf = self else { return }
      guard let email = email else {
        strongSelf.showMessagePrompt("email can't be empty")
        return
      }
      strongSelf.showTextInputPrompt(withMessage: "Password:") { userPressedOK, password in
        guard let password = password else {
          strongSelf.showMessagePrompt("password can't be empty")
          return
        }
        strongSelf.showSpinner {
          // [START create_user]
          Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            // [START_EXCLUDE]
            strongSelf.hideSpinner {
              guard let authResult = authResult, error == nil else {
                strongSelf.showMessagePrompt(error!.localizedDescription)
                return
              }
              print("\(authResult.user.email!) created")
              strongSelf.navigationController?.popViewController(animated: true)
            }
            // [END_EXCLUDE]
          }
          // [END create_user]
        }
      }
    }
  }

}
