//
//  MyTopPostsViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseDatabase

@objc(MyTopPostsViewController)
class MyTopPostsViewController: MyPostsViewController {
  override func getQuery() -> FIRDatabaseQuery {
    return super.getQuery().queryOrderedByChild("starCount")
  }
}
