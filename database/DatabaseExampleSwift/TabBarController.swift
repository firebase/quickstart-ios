//
//  TabBarViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/10/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseAuth

@objc(TabBarController)
class TabBarController: UITabBarController {

  @IBAction func didTapSignOut(sender: AnyObject) {
    let firebaseAuth = FIRAuth.auth()
    do {
      try firebaseAuth?.signOut()
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}
