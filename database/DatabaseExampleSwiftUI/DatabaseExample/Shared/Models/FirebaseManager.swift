//
//  FirebaseManager.swift
//  DatabaseExample
//
//  Created by Judy Liu on 7/19/21.
//

import Foundation
import Firebase

class FirebaseManager {
  @Published var posts: [PostViewModel] = []
  var ref: DatabaseReference!
  private var refHandle: DatabaseHandle?

  func getPosts(tabOpened: String) {
    if tabOpened == "recentPosts" {
      let postListRef = ref.child("posts")
      fetchPosts(forRef: postListRef, tabOpened: tabOpened)
    } else if tabOpened == "myPosts" {
      if let userID = Auth.auth().currentUser?.uid {
        let userPostListRef = Database.database().reference()
          .child("user-posts")
          .child(userID)
        fetchPosts(forRef: userPostListRef, tabOpened: tabOpened)
      } else {
        print("error: fetch myPosts was not successful")
      }
    }
  }

  func fetchPosts(forRef ref: DatabaseReference, tabOpened: String) {
    // read data by listening for value events
    refHandle = ref.observe(DataEventType.value, with: { snapshot in
      // retrieved data is of type dictionary of dictionary
      guard let value = snapshot.value as? [String: [String: Any]] else { return }
      // sort dictionary by keys (most to least recent)
      let sortedValues = value.sorted(by: { $0.key > $1.key })
      // store content of sorted dictionary into "posts" variable
      self.posts = sortedValues.compactMap { PostViewModel(id: $0, dict: $1) }
    })
  }
}
