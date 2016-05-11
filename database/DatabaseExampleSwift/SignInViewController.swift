//
//  SignInViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

@objc(SignInViewController)
class SignInViewController: UIViewController, UITextFieldDelegate {

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!
  var ref:FIRDatabaseReference!

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.view.endEditing(true)
  }

  override func viewDidAppear(animated: Bool) {
    if FIRAuth.auth()?.currentUser {
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
            }
          })
          ref.child("users").child(user?.uid).observeSingleEventOfType(.Value, withBlock: { snapshot in
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
                        self.ref.child("users").setValue(["username": username])
                        self.performSegueWithIdentifier("signIn", sender: nil)
                      })
                    }
                  })
                } else {
                  self.showMessagePrompt("username can't be empty")
                }
              }
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
                    })
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
                          self.ref.child("users").setValue(["username": username])
                          // [END basic_write]
                          self.performSegueWithIdentifier("signIn", sender: nil)
                        })
                      }
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

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    segue.destinationViewController.childViewControllers[0].navigationItem.title = "Chat as \(FIRAuth.auth()?.currentUser?.displayName)"
  }
}
