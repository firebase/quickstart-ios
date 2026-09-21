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

class PostListViewModel: ObservableObject {
  @Published var alert = false
  @Published var alertMessage = ""
  @Published var posts: [PostViewModel] = []

  // setup instance of FIRDatabaseReference for reading and writing data
  private var ref = Database.root
  private var refHandle: DatabaseHandle?
  // The handle has to be handed back to the same reference it came from.
  private var observedRef: DatabaseReference?

  // function called when error occurs
  private func showAlertMessage(message: String) {
    alertMessage = message
    alert.toggle()
  }

  private func getCurrentUserID() -> String? {
    return Auth.auth().currentUser?.uid
  }

  // function called when user is making a new post
  func didTapPostButton(title: String, body: String) {
    // check if both title and body are completed
    if title.isEmpty || body.isEmpty {
      showAlertMessage(message: "Neither title nor body can be empty.")
      return
    }

    if let userID = getCurrentUserID() {
      let postListRef = ref.child("posts")
      guard let key = postListRef.childByAutoId().key else { return }
      let post = ["uid": userID,
                  "author": Auth.auth().currentUser?.email,
                  "title": title,
                  "body": body]
      let childUpdates = ["/posts/\(key)": post,
                          "/user-posts/\(String(describing: userID))/\(key)/": post]
      ref.updateChildValues(childUpdates)
    }
  }

  func getPosts(postsType: PostsType) {
    switch postsType {
    case .recentPosts:
      let postListRef = ref.child("posts")
      fetchPosts(from: postListRef, for: postsType)
    case .myPosts, .topPosts:
      if let userID = getCurrentUserID() {
        let userPostListRef = Database.database().reference()
          .child("user-posts")
          .child(userID)
        fetchPosts(from: userPostListRef, for: postsType)
      } else {
        print("error: fetch myPosts was not successful")
      }
    }
  }

  private func fetchPosts(from ref: DatabaseReference, for postsType: PostsType) {
    // getPosts() runs on every onAppear, so don't stack up listeners
    removeObserver()
    // read data by listening for value events
    observedRef = ref
    refHandle = ref.observe(DataEventType.value, with: { snapshot in
      // retrieved data is of type dictionary of dictionary
      guard let value = snapshot.value as? [String: [String: Any]] else { return }

      switch postsType {
      case .recentPosts, .myPosts:
        // sort dictionary by keys (most to least recent)
        let sortedValues = value.sorted(by: { $0.key > $1.key })
        // store content of sorted dictionary into "posts" variable
        self.posts = sortedValues.compactMap { PostViewModel(id: $0, dict: $1) }
      case .topPosts:
        let sortedValues = value
          .sorted(by: { $0.value["starCount"] as? Int ?? 0 > $1.value["starCount"] as? Int ?? 0 })
        self.posts = sortedValues.compactMap { PostViewModel(id: $0, dict: $1) }
      }
    })
  }

  func onViewDisappear() {
    removeObserver()
  }

  private func removeObserver() {
    if let refHandle = refHandle, let observedRef = observedRef {
      observedRef.removeObserver(withHandle: refHandle)
    }
    refHandle = nil
    observedRef = nil
  }
}
