//
//  Copyright 2021 Google LLC
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

struct ContentView: View {
  var body: some View {
    NavigationView {
      List {
        VStack(alignment: .leading) {
          Text("Getting Started with Firebase")
          Text("An Introduction to Firebase")
            .font(.subheadline)
        }
        VStack(alignment: .leading) {
          Text("Google Firestore")
          Text("Powerful Querying and Automatic Scaling")
            .font(.subheadline)
        }
        VStack(alignment: .leading) {
          Text("Analytics")
          Text("Simple App Insights")
            .font(.subheadline)
        }
        VStack(alignment: .leading) {
          Text("Remote Config")
          Text("Parametrize App Behavior")
            .font(.subheadline)
        }
      }
      .navigationTitle("Firenotes")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
