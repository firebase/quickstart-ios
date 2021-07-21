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
  @ObservedObject var user = UserViewModel()
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @State private var newPostTitle: String = ""
  @State private var newPostBody: String = ""
  @State private var placeholderText: String = "Say something..."
  var screenWidth = UIScreen.main.bounds.width
  var screenHeight = UIScreen.main.bounds.height

  var body: some View {
    VStack {
      TextField("Add a title", text: $newPostTitle)
        .font(.largeTitle)
        .frame(
          width: screenWidth * 0.88,
          height: screenHeight * 0.08,
          alignment: .leading
        )
        .textFieldStyle(RoundedBorderTextFieldStyle())
      ZStack {
        if newPostBody.isEmpty {
          TextEditor(text: $placeholderText)
            .foregroundColor(.gray)
            .frame(
              width: screenWidth * 0.88,
              alignment: .leading
            )
            .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        }
        TextEditor(text: $newPostBody)
          .frame(
            width: screenWidth * 0.88,
            alignment: .leading
          )
          .opacity(self.newPostBody.isEmpty ? 0.25 : 1)
      }
    }
    .alert(isPresented: $user.alert, content: {
      Alert(
        title: Text("Message"),
        message: Text(user.alertMessage),
        dismissButton: .destructive(Text("Ok"))
      )
    })
    .navigationTitle("New Post")
    .navigationBarItems(trailing:
      Button(action: {
        user.didTapPostButton(
          title: newPostTitle,
          body: newPostBody
        )
        self.presentationMode.wrappedValue.dismiss()
      }) {
        Text("Post")
      })
  }
}

struct NewPostsView_Previews: PreviewProvider {
  static var previews: some View {
    NewPostsView()
  }
}
