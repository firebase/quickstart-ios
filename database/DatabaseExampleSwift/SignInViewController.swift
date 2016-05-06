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
class SignInViewController: UIViewController {

  var ref:FIRDatabaseReference!
  @IBOutlet weak var emailField: UITextField!

  @IBAction func didTapSignUp(sender: AnyObject) {
    FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      self.ref = FIRDatabase().reference()
      self.ref.child("users").setValue(["username": self.emailField.text as String!])
      self.performSegueWithIdentifier("signIn", sender: nil)
    }
  }

  // MARK: - UITextFieldDelegate protocol methods
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    didTapSignUp([])
    return true
  }
}
