//
//  SignInView.swift
//  FirestoreSwiftUIExample
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

struct SignInView: View {
  @State private var isSignedIn = false

  var body: some View {
    NavigationView {
      VStack {
        NavigationLink(
          destination: RestaurantListView().navigationBarHidden(true),
          isActive: $isSignedIn
        )
          { EmptyView() }
        Button("Sign In Anonymously") {
          Auth.auth().signInAnonymously { authResult, error in
            if error == nil {
              self.isSignedIn = true
            } else {
              print(error!)
            }
          }
        }
      }
    }
  }
}

struct SignInView_Previews: PreviewProvider {
  static var previews: some View {
    SignInView()
  }
}
