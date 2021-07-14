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

struct PostCellView: View {
  @State private var isStarred = false
  var post: Post
  var body: some View {
    NavigationLink(destination: PostDetailView(post: post)) {
      VStack {
        VStack(alignment: .leading) {
          HStack(spacing: 1) {
            Image(systemName: "person.fill")
            Text(post.author)
            Spacer()
            Image(systemName: isStarred ? "star.fill" : "star")
              .onTapGesture {
                isStarred.toggle()
              }
            Text("\(post.starCount)")
          }
          Text(post.title)
            .font(.system(size: 27))
            .bold()
          Text(post.body)
        }
      }
    }
  }
}

struct PostCellView_Previews: PreviewProvider {
  static var examplePost = Post(
    id: "postID",
    uid: "userID",
    author: "userEmail",
    title: "postTitle",
    body: "postBody"
  )
  static var previews: some View {
    List {
      ForEach(0 ..< 10) { post in
        PostCellView(post: examplePost)
      }
    }
  }
}
