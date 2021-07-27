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

struct ContentView: View {
  @AppStorage("isSignedIn") var isSignedIn = true
  @State private var selection: Tab = .recentPosts

  enum Tab {
    case recentPosts, myPosts, topPosts
  }

  var body: some View {
    if isSignedIn {
      TabView(selection: $selection) {
        PostsView(title: "Recents", postsType: Tab.recentPosts)
          .tabItem {
            Label("Recents", systemImage: "arrow.counterclockwise")
          }
          .tag(Tab.recentPosts)
        PostsView(title: "My Posts", postsType: Tab.myPosts)
          .tabItem {
            Label("My Posts", systemImage: "person.fill")
          }
          .tag(Tab.myPosts)
        PostsView(title: "My Top Posts", postsType: Tab.topPosts)
          .tabItem {
            Label("My Top Posts", systemImage: "star.fill")
          }
          .tag(Tab.topPosts)
      }
      .accentColor(Color(.systemTeal))
    } else {
      LoginView()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
