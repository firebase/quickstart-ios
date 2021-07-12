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

class UserViewModel: ObservableObject {
  @AppStorage("isSignedIn") var isSignedIn = false

  @Published var email = ""
  @Published var password = ""
  @Published var alertMessage = ""
  @Published var isLoading = false
  @Published var alert = false
  @Published var posts: [Post] = []
  var ref: DatabaseReference!
  var postRef: DatabaseReference!
  var refHandle: DatabaseHandle?

  func showAlertMessage() {
    alertMessage = "Email or password cannot be empty."
    alert.toggle()
    return
  }

  func login() {
    // check if all fields are inputted correctly
    if email.isEmpty || password.isEmpty {
      showAlertMessage()
    }

    // begin loading animation
    withAnimation {
      self.isLoading.toggle()
    }

    // sign in with email and password
    Auth.auth().signIn(withEmail: email, password: password) { result, err in
      withAnimation {
        self.isLoading.toggle()
      }
      if let err = err {
        self.alertMessage = err.localizedDescription
        self.alert.toggle()
      } else {
        self.isSignedIn = true
      }
    }
  }

  func signUp() {
    // check if all fields are inputted correctly
    if email.isEmpty || password.isEmpty {
      showAlertMessage()
    }

    // begin loading animation
    withAnimation {
      self.isLoading.toggle()
    }

    // sign up with email and password
    Auth.auth().createUser(withEmail: email, password: password) { result, err in
      withAnimation {
        self.isLoading.toggle()
      }
      if let err = err {
        self.alertMessage = err.localizedDescription
        self.alert.toggle()
      } else {
        self.login()
      }
    }
  }

  func logout() {
    do {
      try Auth.auth().signOut()
      withAnimation {
        self.isSignedIn = false
      }
      email = ""
      password = ""
    } catch {
      NSLog("Error signing out.")
    }
  }

  func post(title: String, body: String) {
    ref = Database.database().reference()
    let userID = Auth.auth().currentUser?.uid
    guard let key = ref.child("posts").childByAutoId().key else { return }
    let post = ["uid": userID,
                "author": Auth.auth().currentUser?.email,
                "title": title,
                "body": body]
    let childUpdates = ["/posts/\(key)": post,
                        "/user-posts/\(String(describing: userID))/\(key)/": post]
    ref.updateChildValues(childUpdates)
    fetchPosts()
  }

  func fetchPosts() {
    posts.removeAll()
    ref = Database.database().reference()
    postRef = ref.child("posts")
    refHandle = postRef.observe(DataEventType.value, with: { snapshot in
      guard let value = snapshot.value as? [String: [String: Any]] else { return }
      self.posts = value.compactMap { Post(dict: $1) }
    })
  }

}

let user = UserViewModel()
