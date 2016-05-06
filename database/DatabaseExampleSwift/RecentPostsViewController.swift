//
//  RecentPostsViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseDatabase

@objc(RecentPostsViewController)
class RecentPostsViewController: PostListViewController {
  override func getQuery() -> FIRDatabaseQuery {
    // Last 100 posts, these are automatically the 100 most recent
    // due to sorting by push() keys
    return (ref?.child("posts").queryLimitedToFirst(100))!
  }
}
