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
    // [START recent_posts_query]
    // Last 100 posts, these are automatically the 100 most recent
    // due to sorting by push() keys
    let recentPostsQuery = (ref?.child("posts").queryLimitedToFirst(100))!
    // [END recent_posts_query]
    return recentPostsQuery
  }
}
