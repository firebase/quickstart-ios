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
  @Published var myPosts: [Post] = []
  private lazy var ref: DatabaseReference = {
    Database.database().reference()
  }()

  private lazy var postRef: DatabaseReference = {
    Database.database().reference().child("posts")
  }()

  private lazy var userPostRef: DatabaseReference = {
    Database.database().reference().child("user-posts").child(getuid())
  }()

  var refHandle: DatabaseHandle?

  func getuid() -> String {
    return Auth.auth().currentUser!.uid
  }

  func showAlertMessage(message: String) {
    alertMessage = message
    alert.toggle()
  }

  func login() {
    // check if all fields are inputted correctly
    if email.isEmpty || password.isEmpty {
      showAlertMessage(message: "Neither email nor password can be empty.")
      return
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
      showAlertMessage(message: "Neither email nor password can be empty.")
      return
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
    // check if both title and body are completed
    if title.isEmpty || body.isEmpty {
      showAlertMessage(message: "Neither title nor body can be empty.")
      return
    }

    // begin loading animation
    withAnimation {
      self.isLoading.toggle()
    }

    let userID = getuid()
    guard let key = postRef.childByAutoId().key else { return }
    let post = ["id": key,
                "uid": userID,
                "author": Auth.auth().currentUser?.email,
                "title": title,
                "body": body]
    let childUpdates = ["/posts/\(key)": post,
                        "/user-posts/\(String(describing: userID))/\(key)/": post]
    ref.updateChildValues(childUpdates)

    // end loading animation
    withAnimation {
      self.isLoading.toggle()
    }
  }

  func fetchPosts() {
    // read data by listening for value events
    refHandle = postRef.observe(DataEventType.value, with: { snapshot in
      // retrieved data is of type dictionary of dictionary
      guard let value = snapshot.value as? [String: [String: Any]] else { return }
      // sort dictionary by keys (most to least recent)
      let sortedValues = value.sorted (by: { $0.key > $1.key })
      // store content of sorted dictionary into "posts" variable
      self.posts = sortedValues.compactMap { Post(dict: $1) }
    })
  }

  func fetchMyPosts() {
    // read data by listening for value events
    refHandle = userPostRef.observe(DataEventType.value, with: { snapshot in
      // retrieved data is of type dictionary of dictionary
      guard let value = snapshot.value as? [String: [String: Any]] else { return }
      // sort dictionary by keys (most to least recent)
      let sortedValues = value.sorted (by: { $0.key > $1.key })
      // store content of sorted dictionary into "posts" variable
      self.myPosts = sortedValues.compactMap { Post(dict: $1) }
    })
  }
}

let user = UserViewModel()
