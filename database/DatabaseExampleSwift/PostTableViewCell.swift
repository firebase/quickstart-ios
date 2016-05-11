//
//  PostTableTableViewCell.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import Firebase

class PostTableViewCell: UITableViewCell {
  @IBOutlet weak var authorImage: UIImageView!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var starButton: UIButton!
  @IBOutlet weak var numStarsLabel: UILabel!
  @IBOutlet weak var postTitle: UILabel!
  @IBOutlet weak var postBody: UITextView!
  var postRef: FIRDatabaseReference!

  @IBAction func didTapStarButton(sender: AnyObject) {
    postRef = FIRDatabase.database().reference().child("posts")
    // [START post_stars_transaction]
    postRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
      if var post = currentData.value {
        let uid = FIRAuth.auth().currentUser.uid
        if let stars = post["stars"] {
          let starCount: Int = post["starCount"]
          if let _ = stars[uid] {
            // Unstar the post and remove self from stars
            starCount--
            starts.remove(uid)
          } else {
            // Star the post and add self to stars
            starCount++
            starts[uid] = true
          }
          post["starCount"] = starCount

          // Set value and report transaction success
          currentData.value = post
          return FIRTransactionResult.successWithValue(currentData)
        }
      }
      return FIRTransactionResult.successWithValue(currentData)
      }) { (error, committed, snapshot) in
        print(error.loc)
    }
  // [END post_stars_transaction]
  }
}
