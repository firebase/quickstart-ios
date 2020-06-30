//
//  Copyright (c) 2018 Google Inc.
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

import Firebase
import UIKit

@objc(PasswordlessViewController)
class PasswordlessViewController: UIViewController {

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var signInButton: UIButton!
  var link: String!

  override func viewDidLoad() {
    super.viewDidLoad()
    emailField.text = UserDefaults.standard.value(forKey: "Email") as? String
    if let link = UserDefaults.standard.value(forKey: "Link") as? String {
      self.link = link
      signInButton.isEnabled = true
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
  }

  @IBAction func didTapSignInWithEmailLink(_ sender: AnyObject) {
    if let email = self.emailField.text {
      showSpinner {
        // [START signin_emaillink]
        Auth.auth().signIn(withEmail: email, link: self.link) { (user, error) in
          // [START_EXCLUDE]
          self.hideSpinner {
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
            self.navigationController!.popViewController(animated: true)
          }
          // [END_EXCLUDE]
        }
        // [END signin_emaillink]
      }
    } else {
      self.showMessagePrompt("Email can't be empty")
    }
  }

  @IBAction func didTapSendSignInLink(_ sender: AnyObject) {
    if let email = self.emailField.text {
      showSpinner {
        // [START action_code_settings]
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://www.example.com")
        // The sign-in operation has to always be completed in the app.
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        actionCodeSettings.setAndroidPackageName("com.example.android",
                                                 installIfNotAvailable: false, minimumVersion: "12")
        // [END action_code_settings]
        // [START send_signin_link]
        Auth.auth().sendSignInLink(toEmail:email,
                                   actionCodeSettings: actionCodeSettings) { error in
          // [START_EXCLUDE]
          self.hideSpinner {
            // [END_EXCLUDE]
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
            // The link was successfully sent. Inform the user.
            // Save the email locally so you don't need to ask the user for it again
            // if they open the link on the same device.
            UserDefaults.standard.set(email, forKey: "Email")
            self.showMessagePrompt("Check your email for link")
            // [START_EXCLUDE]
          }
          // [END_EXCLUDE]
        }
        // [END send_signin_link]
      }
    } else {
      self.showMessagePrompt("Email can't be empty")
    }
  }
}
