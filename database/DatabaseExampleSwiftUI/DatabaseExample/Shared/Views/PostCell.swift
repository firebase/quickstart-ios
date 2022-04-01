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

struct PostCell: View {
  @StateObject var post: PostViewModel

  var body: some View {
    NavigationLink(destination: PostDetailView(post: post)) {
      VStack {
        VStack(alignment: .leading) {
          HStack(spacing: 1) {
            Image(systemName: "person.fill")
            Text(post.author)
            Spacer()
            let starButton = Image(systemName: post.isStarred ? "star.fill" : "star")
            #if os(iOS) || os(macOS)
              starButton
                .onTapGesture {
                  if #available(iOS 15, macOS 12, *) {
                    #if compiler(>=5.5) && canImport(_Concurrency)
                      Task { await
                        post.didTapStarButtonAsync()
                      }
                    #else
                      post.didTapStarButton()
                    #endif
                  } else {
                    post.didTapStarButton()
                  }
                }
            #elseif os(tvOS)
              starButton
            #endif
            Text("\(post.starCount)")
          }
          Text(post.title)
            .font(.system(size: 27))
            .bold()
          Text(post.body)
        }
      }
      .onAppear {
        post.onViewAppear()
      }
      .onDisappear {
        post.onViewDisappear()
      }
    }
  }
}

struct PostCell_Previews: PreviewProvider {
  static var examplePost = PostViewModel(
    id: "postID",
    uid: "userID",
    author: "userEmail",
    title: "postTitle",
    body: "postBody"
  )
  static var previews: some View {
    PostCell(post: examplePost)
  }
}
