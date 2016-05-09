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
class MyTopPostsViewController: PostListViewController {
  override func getQuery() -> FIRDatabaseQuery {
    // [START my_top_posts_query]
    // My top posts by number of stars
    let myTopPostsQuery = (ref.child("user-posts").child(getUid())).queryOrderedByChild("starCount")
    // [END my_top_posts_query]
    return myTopPostsQuery
  }
}
