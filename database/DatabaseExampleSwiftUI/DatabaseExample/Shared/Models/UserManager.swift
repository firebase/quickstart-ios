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

import SwiftUI
import Firebase

class UserManager: ObservableObject {

  @AppStorage("log_status") var status = false

  @Published var email = ""
  @Published var password = ""
  @Published var alertMsg = ""
  @Published var isLoading = false
  @Published var alert = false

  func login() {

    // check if all fields are inputted correctly
    if email == "" || password == "" {
      self.alertMsg = "Email or password cannot be empty."
      self.alert.toggle()
      return
    }

    // begin loading animation
    withAnimation {
      self.isLoading.toggle()
    }

    // sign in with email and password
    Auth.auth().signIn(withEmail: email, password: password) { (result, err) in
      withAnimation {
        self.isLoading.toggle()
      }
      if err != nil {
        self.alertMsg = err!.localizedDescription
        self.alert.toggle()
      }
      else {
        self.status = true
      }
    }
  }

  func signUp() {

    // check if all fields are inputted correctly
    if email == "" || password == "" {
      self.alertMsg = "Email or password cannot be empty."
      self.alert.toggle()
      return
    }

    // begin loading animation
    withAnimation {
      self.isLoading.toggle()
    }

    // sign up with email and password
    Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
      withAnimation{
        self.isLoading.toggle()
      }
      if err != nil {
        self.alertMsg = err!.localizedDescription
        self.alert.toggle()
      }
      else {
        self.login()
      }
    }

    // login after creating user
    self.login()
  }

  func logout() {
    try! Auth.auth().signOut()
    withAnimation {
      self.status = false
    }
    email = ""
    password = ""
  }

}

let user = UserManager()
