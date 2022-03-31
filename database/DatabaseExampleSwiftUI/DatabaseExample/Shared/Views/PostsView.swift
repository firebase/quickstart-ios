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

struct PostsView: View {
  @StateObject var postList = PostListViewModel()
  @StateObject var user = UserViewModel()

  // define variables for creating a new post for iOS
  #if os(iOS) || os(tvOS)
    @State private var newPostsViewPresented = false
  #endif

  var title: String
  var postsType: PostsType

  var body: some View {
    NavigationView {
      let postListView = List {
        ForEach(postList.posts) { post in
          PostCell(post: post)
        }
      }
      .onAppear {
        postList.getPosts(postsType: postsType)
      }
      .onDisappear {
        postList.onViewDisappear()
      }
      .navigationTitle(title)
      #if os(iOS) || os(tvOS)
        postListView
          .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
              Button(action: {
                user.logout()
              }) {
                HStack {
                  Image(systemName: "chevron.left")
                  Text("Logout")
                }
              }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button(action: {
                newPostsViewPresented = true
              }) {
                Image(systemName: "plus")
              }
              .sheet(isPresented: $newPostsViewPresented) {
                NewPostsView(postList: postList, isPresented: $newPostsViewPresented)
              }
            }
          }
      #elseif os(macOS)
        postListView
      #endif
    }
  }
}

struct PostsView_Previews: PreviewProvider {
  static var previews: some View {
    PostsView(title: "Recents", postsType: PostsType.recentPosts)
  }
}
