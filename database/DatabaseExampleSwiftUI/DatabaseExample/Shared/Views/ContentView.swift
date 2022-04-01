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

struct ContentView: View {
  @AppStorage("isSignedIn") var isSignedIn = false

  // define variables for creating a new post for macOS
  #if os(macOS) || os(tvOS)
    @StateObject var postList = PostListViewModel()
    @State private var newPostsViewPresented = false
  #endif

  var body: some View {
    if isSignedIn {
      let tabView = TabView {
        PostsView(title: "Recents", postsType: .recentPosts)
          .tabItem {
            Label("Recents", systemImage: "arrow.counterclockwise")
          }
        PostsView(title: "My Posts", postsType: .myPosts)
          .tabItem {
            Label("My Posts", systemImage: "person.fill")
          }
        PostsView(title: "My Top Posts", postsType: .topPosts)
          .tabItem {
            Label("My Top Posts", systemImage: "star.fill")
          }
      }
      .accentColor(Color(.systemTeal))

      #if os(iOS) || os(tvOS)
        tabView
      #elseif os(macOS)
        tabView
          .toolbar {
            Button(action: {
              user.logout()
            }) {
              HStack {
                Image(systemName: "chevron.left")
                Text("Logout")
              }
            }
            Spacer()
            Button(action: {
              newPostsViewPresented = true
            }) {
              Image(systemName: "plus")
            }
            .sheet(isPresented: $newPostsViewPresented) {
              NewPostsView(postList: postList, isPresented: $newPostsViewPresented)
            }
          }
      #endif
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
