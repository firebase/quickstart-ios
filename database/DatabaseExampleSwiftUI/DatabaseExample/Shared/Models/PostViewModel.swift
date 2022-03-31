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

import Combine
import FirebaseAuth
import FirebaseDatabase

class PostViewModel: ObservableObject, Identifiable {
  @Published var id: String
  @Published var uid: String
  @Published var author: String
  @Published var title: String
  @Published var body: String
  @Published var starCount: Int
  @Published var comments: [Comment] = []
  @Published var isStarred: Bool = false
  private var userIDsStarredBy: [String: Bool] {
    didSet {
      refreshIsStarred()
    }
  }

  // setup instance of FIRDatabaseReference for reading and writing data
  private var ref = Database.root
  private var refHandle: DatabaseHandle?

  init(id: String, uid: String, author: String, title: String, body: String) {
    self.id = id
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    starCount = 0
    userIDsStarredBy = [:]
    refreshIsStarred()
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
    refreshIsStarred()
  }

  private func refreshIsStarred() {
    isStarred = {
      if let uid = getCurrentUserID() {
        return userIDsStarredBy[uid] ?? false
      }
      return false
    }()
  }

  private func getCurrentUserID() -> String? {
    return Auth.auth().currentUser?.uid
  }

  func didTapSendButton(commentField: String) {
    if let userID = getCurrentUserID(),
      let userEmail = Auth.auth().currentUser?.email {
      let commentRef = ref.child("post-comments").child(id)
      guard let key = commentRef.childByAutoId().key else { return }
      let comment = ["uid": userID,
                     "author": userEmail,
                     "text": commentField]
      commentRef.child(key).setValue(comment)
    } else {
      print("Error sending comments.")
    }
  }

  func fetchComments() {
    let commentRef = ref.child("post-comments").child(id)
    refHandle = commentRef.observe(DataEventType.value, with: { snapshot in
      guard let comments = snapshot.value as? [String: [String: Any]] else { return }
      let sortedComments = comments.sorted(by: { $0.key > $1.key })
      self.comments = sortedComments.compactMap { Comment(id: $0, dict: $1) }
    })
  }

  #if compiler(>=5.5) && canImport(_Concurrency)
    @available(iOS 15, tvOS 15, macOS 12, watchOS 8, *)
    func didTapStarButtonAsync() async {
      // updating firebase values
      let postListRef = ref.child("posts").child(id)
      incrementStars(for: postListRef)
      let (snapshot, _) = await postListRef.observeSingleEventAndPreviousSiblingKey(of: .value)
      guard let value = snapshot.value as? [String: Any] else { return }
      if let uid = value["uid"] as? String {
        let userPostRef = Database.database().reference()
          .child("user-posts")
          .child(uid)
          .child(id)
        incrementStars(for: userPostRef)
      }
    }
  #endif

  func didTapStarButton() {
    // updating firebase values
    let postListRef = ref.child("posts").child(id)
    incrementStars(for: postListRef)
    postListRef.observeSingleEvent(of: .value, with: { snapshot in
      guard let value = snapshot.value as? [String: Any] else { return }
      if let uid = value["uid"] as? String {
        let userPostRef = Database.database().reference()
          .child("user-posts")
          .child(uid)
          .child(self.id)
        self.incrementStars(for: userPostRef)
      }
    })
  }

  private func updateStars() {
    let postListRef = ref.child("posts").child(id)
    refHandle = postListRef.observe(DataEventType.value, with: { snapshot in
      guard let post = snapshot.value as? [String: AnyObject] else { return }
      self.starCount = post["starCount"] as? Int ?? 0
      self.userIDsStarredBy = post["userIDsStarredBy"] as? [String: Bool] ?? [:]
    })
  }

  private func incrementStars(for ref: DatabaseReference) {
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

  func onViewAppear() {
    updateStars()
  }

  // remove all handlers when current view disappears
  func onViewDisappear() {
    if let refHandle = refHandle {
      ref.child("posts").child(id).removeObserver(withHandle: refHandle)
    }
  }

  func onDetailViewDisappear() {
    if let refHandle = refHandle {
      ref.child("post-comments").child(id).removeObserver(withHandle: refHandle)
    }
  }
}
