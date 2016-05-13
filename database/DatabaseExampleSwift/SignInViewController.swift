//
//  Copyright (c) 2015 Google Inc.
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

@objc(SignInViewController)
class SignInViewController: UIViewController, UITextFieldDelegate {

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!
  var ref:FIRDatabaseReference!

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.view.endEditing(true)
  }

  override func viewDidAppear(animated: Bool) {
    if FIRAuth.auth()?.currentUser != nil {
      self.performSegueWithIdentifier("signIn", sender: nil)
    }
    ref = FIRDatabase.database().reference()
  }

  @IBAction func didTapEmailLogin(sender: AnyObject) {
    if let email = self.emailField.text, password = self.passwordField.text {
      showSpinner({
        FIRAuth.auth()?.signInWithEmail(email, password: password) { (user, error) in
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            } else if let user = user {
              self.ref.child("users").child(user.uid).observeSingleEventOfType(.Value, withBlock: { snapshot in
                if (!snapshot.exists()) {
                  self.showTextInputPromptWithMessage("Username:") { (userPressedOK, username) in
                    if let username = username {
                      self.showSpinner({
                        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                        changeRequest?.displayName = username
                        changeRequest?.commitChangesWithCompletion() { (error) in
                          self.hideSpinner({
                            if let error = error {
                              self.showMessagePrompt(error.localizedDescription)
                              return
                            }
                            self.ref.child("users").child(FIRAuth.auth()!.currentUser!.uid).setValue(["username": username])
                            self.performSegueWithIdentifier("signIn", sender: nil)
                          })
                        }
                      })
                    } else {
                      self.showMessagePrompt("username can't be empty")
                    }
                  }
                } else {
                  self.performSegueWithIdentifier("signIn", sender: nil)
                }
              })
            }
          })

        }
      })
    } else {
      self.showMessagePrompt("email/password can't be empty")
    }
  }

  @IBAction func didTapSignUp(sender: AnyObject) {
    showTextInputPromptWithMessage("Email:") { (userPressedOK, email) in
      if let email = email {
        self.showTextInputPromptWithMessage("Password:") { (userPressedOK, password) in
          if let password = password {
            self.showTextInputPromptWithMessage("Username:") { (userPressedOK, username) in
              if let username = username {
                self.showSpinner({
                  FIRAuth.auth()?.createUserWithEmail(email, password: password) { (user, error) in
                    self.hideSpinner({
                      if let error = error {
                        self.showMessagePrompt(error.localizedDescription)
                        return
                      }
                      self.showSpinner({
                        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                        changeRequest?.displayName = username
                        changeRequest?.commitChangesWithCompletion() { (error) in
                          self.hideSpinner({
                            if let error = error {
                              self.showMessagePrompt(error.localizedDescription)
                              return
                            }
                            // [START basic_write]
                            self.ref.child("users").child(user!.uid).setValue(["username": username])
                            // [END basic_write]
                            self.performSegueWithIdentifier("signIn", sender: nil)
                        })
                      }
                    })
                    })
                  }
                })
              } else {
                self.showMessagePrompt("username can't be empty")
              }
            }
          } else {
            self.showMessagePrompt("password can't be empty")
          }
        }
      } else {
        self.showMessagePrompt("email can't be empty")
      }
    }
  }


  // MARK: - UITextFieldDelegate protocol methods
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    didTapEmailLogin([])
    return true
  }
}
