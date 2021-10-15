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

struct NewPostsView: View {
  @ObservedObject var postList = PostListViewModel()
  @Binding var isPresented: Bool
  @State private var newPostTitle: String = ""
  @State private var newPostBody: String = ""

  var body: some View {
    HStack {
      Button(action: {
        isPresented = false
      }) {
        Image(systemName: "chevron.left")
      }
      Spacer()
      Button(action: {
        isPresented = false
        postList.didTapPostButton(
          title: newPostTitle,
          body: newPostBody
        )
      }) {
        Text("Post")
      }
    }
    .padding(20)
    VStack {
      // post title
      let postTitleInput = TextField("Add a title", text: $newPostTitle)
        .font(.largeTitle)
        .padding()

      #if os(iOS) || os(tvOS)
        postTitleInput
          .frame(
            width: ScreenDimensions.width * 0.88,
            height: ScreenDimensions.height * 0.08,
            alignment: .leading
          )
      #elseif os(macOS)
        postTitleInput
          .frame(minWidth: 400)
      #endif

      // post body
      #if os(iOS) || os(macOS)
        let postBodyInput = TextEditor(text: $newPostBody)
          .padding()
      #elseif os(tvOS)
        let postBodyInput = TextField("Say something...", text: $newPostBody)
          .padding()
      #endif

      #if os(iOS) || os(tvOS)
        postBodyInput
          .frame(
            width: ScreenDimensions.width * 0.88,
            alignment: .leading
          )
      #elseif os(macOS)
        postBodyInput
          .frame(minWidth: 300, minHeight: 300)
      #endif
    }
    .alert(isPresented: $postList.alert, content: {
      Alert(
        title: Text("Message"),
        message: Text(postList.alertMessage),
        dismissButton: .destructive(Text("Ok"))
      )
    })
    .navigationTitle("New Post")
  }
}

struct NewPostsView_Previews: PreviewProvider {
  static var previews: some View {
    NewPostsView(isPresented: .constant(true))
  }
}
