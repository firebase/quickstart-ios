//
//  Copyright (c) 2021 Google Inc.
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

import SwiftUI
import Firebase

class PostViewModel: ObservableObject, Identifiable {
  @Published var id: String
  @Published var uid: String
  @Published var author: String
  @Published var title: String
  @Published var body: String
  @Published var starCount: Int
  @Published var userIDsStarredBy: [String: Bool]
  var postRef: DatabaseReference!
  var isStarred: Bool {
    if let uid = Auth.auth().currentUser?.uid {
      return userIDsStarredBy[uid] ?? false
    }
    return false
  }

  private var refHandle: DatabaseHandle?

  init(id: String, uid: String, author: String, title: String, body: String) {
    self.id = id
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    starCount = 0
    userIDsStarredBy = [:]
  }

  init?(id: String, dict: [String: Any]) {
    guard let uid = dict["uid"] as? String else { return nil }
    guard let author = dict["author"] as? String else { return nil }
    guard let title = dict["title"] as? String else { return nil }
    guard let body = dict["body"] as? String else { return nil }
    let userIDsStarredBy = dict["userIDsStarredBy"] as? [String: Bool] ?? [:]
    let starCount = dict["starCount"] as? Int ?? 0

    self.id = id
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    self.starCount = starCount
    self.userIDsStarredBy = userIDsStarredBy
  }

  func didTapStarButton() {
    // updating firebase values
    postRef = Database.database().reference().child("posts").child(id)
    incrementStars(forRef: postRef)
    postRef.observeSingleEvent(of: .value, with: { snapshot in
      guard let value = snapshot.value as? [String: Any] else { return }
      if let uid = value["uid"] as? String {
        let userPostRef = Database.database().reference()
          .child("user-posts")
          .child(uid)
          .child(self.id)
        self.incrementStars(forRef: userPostRef)
      }
    })
  }

  func updateStars() {
    postRef = Database.database().reference().child("posts").child(id)
    refHandle = postRef.observe(DataEventType.value, with: { snapshot in
      guard let post = snapshot.value as? [String: AnyObject] else { return }
      self.starCount = post["starCount"] as? Int ?? 0
      self.userIDsStarredBy = post["userIDsStarredBy"] as? [String: Bool] ?? [:]
    })
  }

  func incrementStars(forRef ref: DatabaseReference) {
    ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
      if var post = currentData.value as? [String: AnyObject],
        let uid = Auth.auth().currentUser?.uid {
        var userIDsStarredBy: [String: Bool]
        userIDsStarredBy = post["userIDsStarredBy"] as? [String: Bool] ?? [:]
        var starCount = post["starCount"] as? Int ?? 0
        if let _ = userIDsStarredBy[uid] {
          // Unstar the post and remove self from stars
          starCount -= 1
          userIDsStarredBy.removeValue(forKey: uid)
        } else {
          // Star the post and add self to stars
          starCount += 1
          userIDsStarredBy[uid] = true
        }
        post["starCount"] = starCount as AnyObject?
        post["userIDsStarredBy"] = userIDsStarredBy as AnyObject?

        // Set value and report transaction success
        currentData.value = post
        return TransactionResult.success(withValue: currentData)
      }
      return TransactionResult.success(withValue: currentData)
    }) { error, committed, snapshot in
      if let error = error {
        print(error.localizedDescription)
      }
    }
  }

  func onViewDisappear() {
    if let refHandle = refHandle {
      postRef.removeObserver(withHandle: refHandle)
    }
  }
}
