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

@objc(PostTableViewCell)
class PostTableViewCell: UITableViewCell {
  @IBOutlet weak var authorImage: UIImageView!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var starButton: UIButton!
  @IBOutlet weak var numStarsLabel: UILabel!
  @IBOutlet weak var postTitle: UILabel!
  @IBOutlet weak var postBody: UITextView!
  var postKey: String?
  var postRef: FIRDatabaseReference!

  @IBAction func didTapStarButton(sender: AnyObject) {
    if let postKey = postKey {
      postRef = FIRDatabase.database().reference().child("posts").child(postKey)
      incrementStarsForRef(postRef)
      postRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
        if let uid = snapshot.value?["uid"] as? String {
          let userPostRef = FIRDatabase.database().reference()
            .child("user-posts")
            .child(uid)
            .child(postKey)
          self.incrementStarsForRef(userPostRef)
        }
      })
    }
  }

  func incrementStarsForRef(ref: FIRDatabaseReference) {
    // [START post_stars_transaction]
    postRef.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
      if currentData.value != nil, let uid = FIRAuth.auth()?.currentUser?.uid {
        var post = currentData.value as! [String : AnyObject]
        var stars : Dictionary<String, Bool>
        stars = post["stars"] as? Dictionary<String, Bool> ?? [:]
        var starCount = post["starCount"] as? Int ?? 0
        if let _ = stars[uid] {
          // Unstar the post and remove self from stars
          starCount -= 1
          stars.removeValueForKey(uid)
        } else {
          // Star the post and add self to stars
          starCount += 1
          stars[uid] = true
        }
        post["starCount"] = starCount
        post["stars"] = stars

        // Set value and report transaction success
        currentData.value = post

        return FIRTransactionResult.successWithValue(currentData)
      }
      return FIRTransactionResult.successWithValue(currentData)
    }) { (error, committed, snapshot) in
      if (error != nil) {
        print(error?.localizedDescription)
      }
    }
    // [END post_stars_transaction]
  }
}
