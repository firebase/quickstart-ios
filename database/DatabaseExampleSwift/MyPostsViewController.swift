//
//  MyPostsViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseDatabase

@objc(MyPostsViewController)
class MyPostsViewController: PostListViewController {
  override func getQuery() -> FIRDatabaseQuery {
    return (ref?.child("user-posts").child(getUid()))!
  }
}
