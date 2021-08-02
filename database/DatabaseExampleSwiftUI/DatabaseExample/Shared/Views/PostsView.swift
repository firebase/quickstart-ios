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

struct PostsView: View {
  @StateObject var postList = PostListViewModel()
  @StateObject var user = UserViewModel()
  var title: String
  var postsType: PostsType

  var body: some View {
    NavigationView {
      List {
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
      .navigationBarTitle(title)
      .navigationBarItems(leading:
        Button(action: {
          user.logout()
        }) {
          HStack {
            Image(systemName: "chevron.left")
            Text("Logout")
          }
        },
        trailing:
        NavigationLink(destination: NewPostsView(postList: postList)) {
          Image(systemName: "plus")
        })
    }
  }
}

struct PostsView_Previews: PreviewProvider {
  static var previews: some View {
    PostsView(title: "Recents", postsType: PostsType.recentPosts)
  }
}
